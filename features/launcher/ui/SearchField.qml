import QtQuick
import qs.core.widgets
import qs.features.launcher.state

// Campo de busca do launcher, ligado à busca do estado. As teclas que não são
// de digitar (setas, Enter, Tab…) vão para `key`, e cada estilo decide o que
// fazem.
SearchBox {
    placeholder: "Buscar aplicativos e ações"
    text: LauncherState.query
    onEdited: t => LauncherState.query = t
}
