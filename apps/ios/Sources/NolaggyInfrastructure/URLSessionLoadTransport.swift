import Foundation
import NolaggyApplication
import NolaggyDomain

/// Configuração de infraestrutura isolada do domínio e da interface para permitir a
/// substituição futura do endpoint sem mudar contratos de medição.
public enum DeepCheckLoadEndpoint {
    public static let pilot = URL(string: "https://nolaggy-deep-check.buildealabs.workers.dev/v1/load")!
}

/// Adaptador do único endpoint de carga autorizado (load-transfer-v2).
/// Encerra por volume ou por tempo, o que ocorrer primeiro.
public struct URLSessionLoadTransport: LoadTransport {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func transfer(_ request: LoadRequest) async -> LoadTransferOutcome {
        let maxRequests = request.isWiFi ? 6 : 1
        let concurrency = request.isWiFi ? 2 : 1
        let totalMaxBytes = request.isWiFi ? 60 * 1024 * 1024 : 10 * 1024 * 1024

        let delegate = LoadChunkDelegate(
            singleDownloadMaxBytes: request.maximumBytes,
            totalMaxBytes: totalMaxBytes
        )
        let downloadSession = URLSession(
            configuration: session.configuration,
            delegate: delegate,
            delegateQueue: nil
        )

        var mutableRequest = URLRequest(url: request.url)
        mutableRequest.cachePolicy = .reloadIgnoringLocalCacheData
        mutableRequest.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        let urlRequest = mutableRequest

        let requestCounter = LoadRequestCounter(maxRequests: maxRequests)

        return await withTaskCancellationHandler(operation: {
            // Termina no prazo da janela de carga ou quando todos os downloads permitidos acabaram,
            // o que vier primeiro. Um trabalhador que esgota a cota não corta o outro no meio.
            await withTaskGroup(of: Void.self) { group in
                group.addTask { [urlRequest] in
                    await withTaskGroup(of: Void.self) { workers in
                        for _ in 0..<concurrency {
                            workers.addTask {
                                while !Task.isCancelled, requestCounter.claimNextRequest() {
                                    if delegate.getTotalBytes() >= totalMaxBytes { break }
                                    _ = await delegate.runSingleDownload(using: downloadSession, request: urlRequest)
                                }
                            }
                        }
                    }
                }
                group.addTask {
                    try? await Task.sleep(for: request.maximumDuration)
                }

                _ = await group.next()
                group.cancelAll()
                delegate.cancelAll()
                downloadSession.invalidateAndCancel()
            }

            let total = delegate.getTotalBytes()
            return total > 0 ? .completed(bytesTransferred: total) : .unavailable
        }, onCancel: {
            delegate.cancelAll()
            downloadSession.invalidateAndCancel()
        })
    }
}

private final class LoadRequestCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    private let maxRequests: Int

    init(maxRequests: Int) {
        self.maxRequests = maxRequests
    }

    func claimNextRequest() -> Bool {
        lock.withLock {
            if count < maxRequests {
                count += 1
                return true
            }
            return false
        }
    }
}

private final class LoadChunkDelegate: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var totalBytes = 0
    private var activeTasks: Set<URLSessionDataTask> = []
    private var taskBytes: [Int: Int] = [:]
    private var taskContinuations: [Int: CheckedContinuation<Int, Never>] = [:]
    private var isCancelled = false
    private let singleDownloadMaxBytes: Int
    private let totalMaxBytes: Int

    init(singleDownloadMaxBytes: Int, totalMaxBytes: Int) {
        self.singleDownloadMaxBytes = singleDownloadMaxBytes
        self.totalMaxBytes = totalMaxBytes
    }

    func getTotalBytes() -> Int {
        lock.withLock { totalBytes }
    }

    func runSingleDownload(using session: URLSession, request: URLRequest) async -> Int {
        guard !Task.isCancelled else { return 0 }
        return await withCheckedContinuation { continuation in
            let task: URLSessionDataTask? = lock.withLock {
                guard !isCancelled else { return nil }
                let task = session.dataTask(with: request)
                activeTasks.insert(task)
                taskBytes[task.taskIdentifier] = 0
                taskContinuations[task.taskIdentifier] = continuation
                return task
            }
            guard let task else {
                continuation.resume(returning: 0)
                return
            }
            task.resume()
        }
    }

    func cancelAll() {
        let tasks = lock.withLock {
            isCancelled = true
            let t = activeTasks
            activeTasks.removeAll()
            for continuation in taskContinuations.values {
                continuation.resume(returning: 0)
            }
            taskContinuations.removeAll()
            return t
        }
        for task in tasks {
            task.cancel()
        }
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            completionHandler(.cancel)
            return
        }
        completionHandler(.allow)
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        let chunkCount = data.count
        guard chunkCount > 0 else { return }

        var shouldCancel = false
        var continuationToResume: CheckedContinuation<Int, Never>?
        var finalTaskBytes = 0

        lock.withLock {
            let current = (taskBytes[dataTask.taskIdentifier] ?? 0) + chunkCount
            taskBytes[dataTask.taskIdentifier] = current
            totalBytes += chunkCount

            if current >= singleDownloadMaxBytes || totalBytes >= totalMaxBytes {
                shouldCancel = true
                finalTaskBytes = current
                continuationToResume = taskContinuations.removeValue(forKey: dataTask.taskIdentifier)
                activeTasks.remove(dataTask)
            }
        }

        if shouldCancel {
            dataTask.cancel()
            continuationToResume?.resume(returning: finalTaskBytes)
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let dataTask = task as? URLSessionDataTask else { return }
        var continuationToResume: CheckedContinuation<Int, Never>?
        var finalTaskBytes = 0

        lock.withLock {
            activeTasks.remove(dataTask)
            continuationToResume = taskContinuations.removeValue(forKey: dataTask.taskIdentifier)
            finalTaskBytes = taskBytes[dataTask.taskIdentifier] ?? 0
        }

        continuationToResume?.resume(returning: finalTaskBytes)
    }
}
