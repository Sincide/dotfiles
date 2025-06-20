import { App } from "astal/gtk3"
import style from "./style.scss"
import Sidebar from "./widget/Sidebar"

App.start({
    css: style,
    main() {
        App.get_monitors().map(Sidebar)
    },
})
