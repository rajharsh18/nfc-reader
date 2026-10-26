package com.gatekey.nfc_reader

import android.content.Context

internal object HceStore {
    private const val PREFS = "gatekey_hce"
    private const val KEY = "payload"

    fun write(context: Context, payload: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY, payload)
            .commit()
    }

    fun read(context: Context): String? {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY, null)
            ?.takeIf { it.isNotEmpty() }
    }

    fun clear(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .remove(KEY)
            .commit()
    }
}
