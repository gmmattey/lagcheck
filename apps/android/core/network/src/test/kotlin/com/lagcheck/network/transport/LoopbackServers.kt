package com.lagcheck.network.transport

import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.util.concurrent.atomic.AtomicInteger
import kotlin.concurrent.thread

/** Servidor UDP de teste em loopback. `responder` devolve a(s) resposta(s) para cada datagrama recebido. */
internal class LoopbackUdpServer(private val responder: (request: ByteArray, index: Int) -> List<ByteArray>) : AutoCloseable {
    private val socket = DatagramSocket(0, InetAddress.getByName("127.0.0.1")).apply { soTimeout = 50 }
    val port: Int get() = socket.localPort
    val received = AtomicInteger()
    @Volatile private var running = true
    private val worker = thread(isDaemon = true, name = "loopback-udp") {
        val buf = ByteArray(2048)
        while (running) {
            val p = DatagramPacket(buf, buf.size)
            try { socket.receive(p) } catch (_: java.net.SocketTimeoutException) { continue } catch (_: java.net.SocketException) { break }
            val req = p.data.copyOfRange(0, p.length)
            val idx = received.getAndIncrement()
            for (resp in responder(req, idx)) socket.send(DatagramPacket(resp, resp.size, p.address, p.port))
        }
    }

    override fun close() { running = false; socket.close(); worker.join(500) }
}
