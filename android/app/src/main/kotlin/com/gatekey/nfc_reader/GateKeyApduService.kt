package com.gatekey.nfc_reader

import android.nfc.cardemulation.HostApduService
import android.os.Bundle

/**
 * Presents the saved card number as an NFC Forum Type 4 tag.
 * A GateKey gate reads the NDEF text record `GK1:` plus the card number.
 */
class GateKeyApduService : HostApduService() {
    private var selected = FileKind.NONE
    private var ndefFile = ByteArray(0)

    override fun processCommandApdu(commandApdu: ByteArray?, extras: Bundle?): ByteArray {
        val apdu = commandApdu ?: return UNKNOWN
        val payload = HceStore.read(this) ?: return NOT_FOUND
        if (ndefFile.isEmpty()) ndefFile = ndefFileFor(payload)

        if (isSelectAid(apdu)) {
            selected = FileKind.NONE
            ndefFile = ndefFileFor(payload)
            return OK
        }

        val fileId = selectedFileId(apdu)
        if (fileId != null) {
            selected = when (fileId) {
                0xE103 -> FileKind.CC
                0xE104 -> FileKind.NDEF
                else -> FileKind.NONE
            }
            return if (selected == FileKind.NONE) NOT_FOUND else OK
        }

        if (isReadBinary(apdu)) {
            val file = when (selected) {
                FileKind.CC -> CC_FILE
                FileKind.NDEF -> ndefFile
                FileKind.NONE -> return NOT_FOUND
            }
            return readBinary(apdu, file)
        }

        return UNKNOWN
    }

    override fun onDeactivated(reason: Int) {
        selected = FileKind.NONE
        ndefFile = ByteArray(0)
    }

    private enum class FileKind { NONE, CC, NDEF }

    companion object {
        private val OK = byteArrayOf(0x90.toByte(), 0x00.toByte())
        private val NOT_FOUND = byteArrayOf(0x6A.toByte(), 0x82.toByte())
        private val UNKNOWN = byteArrayOf(0x6D.toByte(), 0x00.toByte())
        private val WRONG_LENGTH = byteArrayOf(0x67.toByte(), 0x00.toByte())
        private val WRONG_PARAM = byteArrayOf(0x6B.toByte(), 0x00.toByte())

        private val AID = byteArrayOf(
            0x00.toByte(),
            0xA4.toByte(),
            0x04.toByte(),
            0x00.toByte(),
            0x07.toByte(),
            0xD2.toByte(),
            0x76.toByte(),
            0x00.toByte(),
            0x00.toByte(),
            0x85.toByte(),
            0x01.toByte(),
            0x01.toByte(),
        )

        // Capability container for a read-only NDEF file at E104.
        private val CC_FILE = byteArrayOf(
            0x00.toByte(),
            0x0F.toByte(),
            0x20.toByte(),
            0x00.toByte(),
            0x3B.toByte(),
            0x00.toByte(),
            0x34.toByte(),
            0x04.toByte(),
            0x06.toByte(),
            0xE1.toByte(),
            0x04.toByte(),
            0x00.toByte(),
            0xFF.toByte(),
            0x00.toByte(),
            0xFF.toByte(),
        )

        private fun isSelectAid(apdu: ByteArray): Boolean {
            return apdu.size >= AID.size && apdu.copyOfRange(0, AID.size).contentEquals(AID)
        }

        private fun isReadBinary(apdu: ByteArray): Boolean {
            return apdu.size >= 4 && apdu[0] == 0x00.toByte() && apdu[1] == 0xB0.toByte()
        }

        private fun selectedFileId(apdu: ByteArray): Int? {
            if (apdu.size < 7) return null
            if (apdu[0] != 0x00.toByte() || apdu[1] != 0xA4.toByte() || apdu[2] != 0x00.toByte()) {
                return null
            }
            val length = apdu[4].toInt() and 0xFF
            if (length < 2) return null
            return ((apdu[5].toInt() and 0xFF) shl 8) or (apdu[6].toInt() and 0xFF)
        }

        private fun readBinary(apdu: ByteArray, file: ByteArray): ByteArray {
            if (apdu.size < 5) return WRONG_LENGTH
            val offset = ((apdu[2].toInt() and 0xFF) shl 8) or (apdu[3].toInt() and 0xFF)
            if (offset < 0 || offset >= file.size) return WRONG_PARAM
            var length = apdu[4].toInt() and 0xFF
            if (length == 0) length = file.size - offset
            val end = minOf(offset + length, file.size)
            return file.copyOfRange(offset, end) + OK
        }

        private fun ndefFileFor(text: String): ByteArray {
            val textBytes = text.toByteArray(Charsets.US_ASCII)
            val payload = ByteArray(3 + textBytes.size)
            payload[0] = 0x02.toByte()
            payload[1] = 'e'.code.toByte()
            payload[2] = 'n'.code.toByte()
            textBytes.copyInto(payload, destinationOffset = 3)
            val message = ByteArray(4 + payload.size)
            message[0] = 0xD1.toByte()
            message[1] = 0x01.toByte()
            message[2] = payload.size.toByte()
            message[3] = 0x54.toByte()
            payload.copyInto(message, destinationOffset = 4)
            val file = ByteArray(2 + message.size)
            file[0] = ((message.size shr 8) and 0xFF).toByte()
            file[1] = (message.size and 0xFF).toByte()
            message.copyInto(file, destinationOffset = 2)
            return file
        }
    }
}
