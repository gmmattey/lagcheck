package com.lagcheck.android.ui.check

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import com.lagcheck.android.ui.tr
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.lagcheck.android.ui.MainViewModel
import com.lagcheck.core.designsystem.components.PrimaryButton
import com.lagcheck.core.designsystem.theme.LagCheckColors
import com.lagcheck.core.designsystem.theme.LagCheckTypography

@Composable
fun RegionalSelectionScreen(
    isConfirming: Boolean,
    viewModel: MainViewModel,
    onBack: () -> Unit
) {
    val language by viewModel.language.collectAsState()

    val txtConfirming = tr("Confirmando referência regional…")

    val txtNoViableTitle = tr("Sem rota viável")

    val txtNoViableMsg = tr("O LagCheck não conseguiu resposta das rotas de referência para sua região.")

    val txtRetry = tr("Testar novamente")

    val txtBack = tr("Voltar para o Início")

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(LagCheckColors.Background)
    ) {
        IconButton(onClick = onBack, modifier = Modifier.size(48.dp)) {
            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = txtBack, tint = LagCheckColors.TextSecondary)
        }

        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 24.dp),
            contentAlignment = Alignment.Center
        ) {
            if (isConfirming) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    CircularProgressIndicator(
                        color = LagCheckColors.AccentPrimary,
                        modifier = Modifier.size(24.dp),
                        strokeWidth = 3.dp
                    )
                    Spacer(modifier = Modifier.height(24.dp))
                    Text(
                        text = txtConfirming,
                        style = LagCheckTypography.BodySemibold,
                        color = LagCheckColors.TextSecondary
                    )
                }
            } else {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Box(
                        modifier = Modifier
                            .size(64.dp)
                            .background(LagCheckColors.Surface, shape = CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "✕",
                            style = LagCheckTypography.SectionHeader,
                            color = LagCheckColors.TextSecondary
                        )
                    }

                    Spacer(modifier = Modifier.height(24.dp))

                    Text(
                        text = txtNoViableTitle,
                        style = LagCheckTypography.SectionHeader,
                        color = LagCheckColors.TextPrimary,
                        textAlign = TextAlign.Center
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    Text(
                        text = txtNoViableMsg,
                        style = LagCheckTypography.BodyMedium,
                        color = LagCheckColors.TextSecondary,
                        textAlign = TextAlign.Center
                    )

                    Spacer(modifier = Modifier.height(48.dp))

                    PrimaryButton(
                        text = txtRetry,
                        onClick = { viewModel.retryCheck() },
                        modifier = Modifier.fillMaxWidth()
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    TextButton(
                        onClick = onBack,
                        modifier = Modifier.height(48.dp)
                    ) {
                        Text(
                            text = txtBack,
                            style = LagCheckTypography.BodySemibold,
                            color = LagCheckColors.AccentPrimary
                        )
                    }
                }
            }
        }
    }
}
