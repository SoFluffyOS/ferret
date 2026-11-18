package io.sofluffy.ferret_handoff

import android.app.assist.AssistContent
import android.app.assist.AssistStructure
import android.content.Context
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.service.voice.VoiceInteractionSession
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView

/**
 * What shows when the user calls the assistant: what's on screen, and one
 * button per paired device to continue it there.
 */
class FerretAssistSession(context: Context) : VoiceInteractionSession(context) {
    private var item: SharedItem? = null
    private var handled = false
    private var card: LinearLayout? = null

    override fun onCreateContentView(): View {
        val root = FrameLayout(context).apply {
            setOnClickListener { hide() }
        }
        val card = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            isClickable = true
            setPadding(dp(20), dp(20), dp(20), dp(12))
            background = GradientDrawable().apply {
                cornerRadius = dp(24).toFloat()
                setColor(colors().surface)
            }
        }
        root.addView(
            card,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                Gravity.BOTTOM,
            ).apply { setMargins(dp(12), dp(12), dp(12), dp(12)) },
        )
        this.card = card
        render()
        return root
    }

    override fun onHide() {
        super.onHide()
        item = null
        handled = false
    }

    @Deprecated("Still the one call every Android version makes for the top activity")
    override fun onHandleAssist(data: Bundle?, structure: AssistStructure?, content: AssistContent?) {
        item = AssistReader.read(context, data, structure, content)
        handled = true
        render()
    }

    private fun render() {
        val card = card ?: return
        val colors = colors()
        card.removeAllViews()

        card.addView(text(context.getString(R.string.ferret_handoff_choose_device), 18f, colors.text))
        val item = item
        if (item == null) {
            if (handled) {
                card.addView(text(context.getString(R.string.ferret_handoff_nothing_on_screen), 14f, colors.muted))
            }
            return
        }

        val summary = item.title ?: item.webUri ?: item.deepLink ?: item.text
        if (summary != null) {
            card.addView(text(summary, 14f, colors.muted).apply { maxLines = 2 })
        }

        val devices = HandoffStore(context).devices()
        if (devices.isEmpty()) {
            card.addView(text(context.getString(R.string.ferret_handoff_no_devices), 14f, colors.muted))
            card.addView(button(context.getString(R.string.ferret_handoff_open_app), colors) {
                HandoffDelivery.openApp(context)
                hide()
            })
            return
        }

        for (device in devices) {
            card.addView(button(device.name, colors) {
                HandoffDelivery.deliver(context, item.copy(targetDeviceId = device.id), device.name)
                hide()
            })
        }
    }

    private fun text(value: String, sizeSp: Float, color: Int) = TextView(context).apply {
        text = value
        setTextColor(color)
        setTextSize(TypedValue.COMPLEX_UNIT_SP, sizeSp)
        setPadding(0, 0, 0, dp(8))
    }

    private fun button(label: String, colors: Palette, onClick: () -> Unit) = Button(context).apply {
        text = label
        isAllCaps = false
        setTextColor(colors.text)
        background = GradientDrawable().apply {
            cornerRadius = dp(14).toFloat()
            setColor(colors.button)
        }
        setOnClickListener { onClick() }
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        ).apply { setMargins(0, dp(4), 0, dp(4)) }
    }

    private fun dp(value: Int): Int = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP,
        value.toFloat(),
        context.resources.displayMetrics,
    ).toInt()

    private fun colors(): Palette {
        val night = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        if (night == Configuration.UI_MODE_NIGHT_YES) {
            return Palette(Color.rgb(44, 44, 46), Color.rgb(58, 58, 60), Color.WHITE, Color.rgb(152, 152, 157))
        }

        return Palette(Color.WHITE, Color.rgb(242, 242, 247), Color.BLACK, Color.rgb(110, 110, 115))
    }

    private data class Palette(val surface: Int, val button: Int, val text: Int, val muted: Int)
}
