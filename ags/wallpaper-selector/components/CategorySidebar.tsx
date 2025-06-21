import { Variable, bind } from 'astal'
import { Widget } from 'astal/gtk3'
import Gtk from 'gi://Gtk'

interface CategorySidebarProps {
  categories: Variable<string[]>
  selectedCategory: Variable<string>
  onCategorySelect: (category: string) => void
}

export function CategorySidebar({ categories, selectedCategory, onCategorySelect }: CategorySidebarProps) {
  function createCategoryButton(category: string) {
    return (
      <button
        className={bind(selectedCategory).as(sel => 
          `category-button ${sel === category ? 'selected' : ''}`
        )}
        onClicked={() => onCategorySelect(category)}
      >
        <box>
          <label 
            label={category.charAt(0).toUpperCase() + category.slice(1)} 
            halign={Gtk.Align.START}
          />
        </box>
      </button>
    )
  }

  return (
    <box className="sidebar" orientation={Gtk.Orientation.VERTICAL} widthRequest={250}>
      <box className="sidebar-header">
        <label label="Categories" className="sidebar-title" />
      </box>
      
      <separator />
      
      <scrollable vexpand>
        <box orientation={Gtk.Orientation.VERTICAL}>
          {bind(categories).as(cats => 
            cats.map(category => createCategoryButton(category))
          )}
        </box>
      </scrollable>
      
      <separator />
      
      <button className="refresh-button" onClicked={() => console.log("Refreshing...")}>
        <label label="Refresh" />
      </button>
    </box>
  )
} 