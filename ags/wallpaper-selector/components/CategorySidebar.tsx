import { Gtk } from "astal/gtk3"
import { Variable } from "astal"

interface CategorySidebarProps {
    categories: string[]
    selectedCategory: Variable<string>
    onCategorySelect: (category: string) => void
}

export default function CategorySidebar({ 
    categories, 
    selectedCategory, 
    onCategorySelect 
}: CategorySidebarProps) {
    return <box 
        className="category-sidebar"
        orientation={Gtk.Orientation.VERTICAL}
        spacing={8}
    >
        <label 
            className="sidebar-title"
            label="Categories"
            halign={Gtk.Align.START}
        />
        
        <box 
            className="category-list"
            orientation={Gtk.Orientation.VERTICAL}
            spacing={4}
        >
            {categories.map(category => (
                <button
                    key={category}
                    className={selectedCategory().bind().as(selected => 
                        `category-button ${selected === category ? 'active' : ''}`
                    )}
                    onClicked={() => onCategorySelect(category)}
                    halign={Gtk.Align.FILL}
                >
                    <label 
                        label={category.charAt(0).toUpperCase() + category.slice(1)}
                        halign={Gtk.Align.START}
                    />
                </button>
            ))}
        </box>
    </box>
} 