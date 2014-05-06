package prof7bit.bitcoin.wallettool

import com.google.bitcoin.core.NetworkParameters
import com.google.bitcoin.core.Wallet
import com.google.bitcoin.crypto.KeyCrypterException
import com.google.bitcoin.store.UnreadableWalletException
import java.io.BufferedInputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileNotFoundException
import java.io.IOException
import org.slf4j.LoggerFactory
import org.spongycastle.crypto.params.KeyParameter

class MultibitWallet implements IWallet {
    static val log = LoggerFactory.getLogger(MultibitWallet)
    var filename = ""
    var Wallet mbwallet
    var NetworkParameters mbparams
    var Boolean encrypted
    var KeyParameter aesKey = null
    var (String)=>String promptFunction = [""]

    override save() {
        saveAs(filename)
    }

    override saveAs(String filename) {
        throw new UnsupportedOperationException("TODO: auto-generated method stub")
    }

    override load(String filename) {
        log.debug("loading wallet file: " + filename)
        this.filename = filename
        var FileInputStream fileInputStream = null
        var BufferedInputStream stream = null

        val walletFile = new File(filename)
        try {
            fileInputStream = new FileInputStream(walletFile)
            stream = new BufferedInputStream(fileInputStream)
            try {
                mbwallet = Wallet.loadFromFileStream(stream)
                stream.close
                fileInputStream.close
                mbparams = mbwallet.networkParameters
                encrypted = mbwallet.encrypted
                if (encrypted) {
                    log.debug("wallet is encrypted")
                    val pass = promptFunction.apply("Wallet is encrypted. Enter pass phrase")
                    if (pass == null || pass.length == 0) {
                        log.debug("no pass phrase entered, will not attempt to decrypt")
                        aesKey = null
                    } else {
                        log.debug("deriving AES key from pass phrase")
                        aesKey = mbwallet.keyCrypter.deriveKey(pass)
                    }
                }

            } catch (UnreadableWalletException e) {
                log.error("unreadable wallet file: " + filename)
                e.printStackTrace
            }
            stream.close
            fileInputStream.close
        } catch (FileNotFoundException e) {
            log.error("file not found: " + filename)
        } catch (IOException e) {
            e.printStackTrace
        }
    }

    override dumpToConsole() {
        if (encrypted && aesKey == null) {
            println("no password entered, will not show keys")
        }
        for (i : 0 ..< keyCount) {
            println(getAddress(i) + " " + getKey(i))
        }
    }

    override setPromptFunction((String)=>String func) {
        promptFunction = func
    }

    override getKeyCount() {
        mbwallet.keychain.length
    }

    override getAddress(int i) {
        mbwallet.keychain.get(i).toAddress(mbparams).toString
    }

    override getKey(int i) {
        val key = mbwallet.keychain.get(i)
        if (key.encrypted) {
            if (aesKey != null) {
                try {
                    val key_unenc = key.decrypt(mbwallet.keyCrypter, aesKey)
                    key_unenc.getPrivateKeyEncoded(mbparams).toString
                } catch (KeyCrypterException e) {
                    "DECRYPTION ERROR " + key.encryptedPrivateKey.toString
                }
            } else {
                "ENCRYPTED"
            }
        } else {
            key.getPrivateKeyEncoded(mbparams).toString
        }
    }
}
