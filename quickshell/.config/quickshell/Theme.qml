import Quickshell
import Quickshell.Io

FileView {
    id: root

    readonly property alias colors: paletteColors
    readonly property DesignTokens design: DesignTokens {}

    path: Quickshell.env("HOME") + "/Dotfiles/themes/everforest-dark-medium/palette.json"
    blockLoading: true
    watchChanges: true
    onFileChanged: reload()

    JsonAdapter {
        property JsonObject colors: JsonObject {
            id: paletteColors

            property string bg_dim
            property string bg0
            property string bg1
            property string bg2
            property string bg3
            property string bg4
            property string bg5
            property string bg_visual
            property string bg_red
            property string bg_yellow
            property string bg_green
            property string bg_blue
            property string bg_purple
            property string fg
            property string red
            property string orange
            property string yellow
            property string green
            property string aqua
            property string blue
            property string purple
            property string grey0
            property string grey1
            property string grey2
            property string statusline1
            property string statusline2
            property string statusline3
        }
    }
}
