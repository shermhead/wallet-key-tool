package prof7bit.bitcoin.wallettool.ui.swing

import com.google.bitcoin.core.ECKey
import com.google.bitcoin.params.MainNetParams
import java.awt.Frame
import java.text.SimpleDateFormat
import javax.swing.JButton
import javax.swing.JDialog
import javax.swing.JLabel
import javax.swing.JTextField
import net.miginfocom.swing.MigLayout
import prof7bit.bitcoin.wallettool.WalletKeyTool
import java.util.TimeZone

class AddKeyDialog extends JDialog{

    var WalletKeyTool keyTool
    var ECKey key = null

    val lbl_key = new JLabel("private key")
    val lbl_address = new JLabel("address")
    val lbl_year = new JLabel("year created")

    val txt_key = new JTextField() => [
        document.addDocumentListener(new DocumentChangedListener [
            ProcessInput
        ])
    ]

    val txt_address = new JTextField => [
        editable = false
    ]

    val txt_year = new JTextField => [
        text = "2009"
        document.addDocumentListener(new DocumentChangedListener [
            ProcessInput
        ])
    ]

    val btn_ok = new JButton("OK") => [
        enabled = false
        addActionListener [
            if (key != null){
                keyTool.add(key)
                visible = false
            }
        ]
    ]

    val btn_cancel = new JButton("Cancel") => [
        addActionListener [
            visible = false
        ]
    ]

    new(Frame owner, WalletKeyTool keyTool) {
        super(owner, "Add key", true)
        this.keyTool = keyTool

        // layout

        layout = new MigLayout("fill", "[right][250,grow,fill][250,grow,fill]", "[][][][20,grow,fill][]")
        add(lbl_key)
        add(txt_key, "spanx 2, wrap")
        add(lbl_address)
        add(txt_address, "spanx 2, wrap")
        add(lbl_year)
        add(txt_year, "spanx 2, wrap")
        add(btn_cancel, "newline, skip")
        add(btn_ok)

        pack
        locationRelativeTo = owner
        visible = true
    }

    /**
     * use the values of private key and creation year to produce
     * a key with proper creation date. If any of the inputs is
     * invalid it will set key=null and disable the ok button.
     * If after this has been run key!=null then we know we have
     * a valid key.
     */
    def void ProcessInput() {
        // FIXME: make this configurable and also move it to a better place
        if (keyTool.params == null) {
            keyTool.params = new MainNetParams
        }

        // key must be valid AND have a valid creation date
        key = keyTool.privkeyStrToECKey(txt_key.text.trim)
        if (key != null) {
            txt_address.text = keyTool.ECKeyToAddressStr(key)
            if (key != null){
                val dfm = new SimpleDateFormat("yyyy");
                dfm.timeZone = TimeZone.getTimeZone("GMT")
                try {
                    key.creationTimeSeconds = dfm.parse(txt_year.text).time / 1000
                    btn_ok.enabled = true
                    println("created" + key.creationTimeSeconds)
                } catch (Exception e) {
                    key = null
                    btn_ok.enabled = false
                }
            }
        } else {
            btn_ok.enabled = false
            if (txt_key.text.length > 0) {
                txt_address.text = "<incomplete or invalid>"
            } else {
                txt_address.text = ""
            }
        }
    }
}
