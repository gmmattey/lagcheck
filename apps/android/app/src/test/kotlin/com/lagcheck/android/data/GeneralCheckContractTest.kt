package com.lagcheck.android.data

import com.google.common.truth.Truth.assertThat
import com.lagcheck.domain.model.OfficialGameCatalog
import org.junit.Test

class GeneralCheckContractTest {
    @Test
    fun `generic gaming catalog entry is distinct from fortnite and valid for general check`() {
        val generic = OfficialGameCatalog.genericGaming
        val fortnite = OfficialGameCatalog.findById("fortnite")

        assertThat(generic.id).isNotEqualTo(fortnite.id)
        assertThat(generic.id).isEqualTo("generic-gaming")
        assertThat(generic.platforms).isNotEmpty()
    }
}
