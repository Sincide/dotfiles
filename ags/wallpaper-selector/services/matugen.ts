import { execAsync } from 'astal'
import GLib from 'gi://GLib'

export interface MatugenColors {
  background: { default: { hex: string } }
  primary: { default: { hex: string } }
  secondary: { default: { hex: string } }
  surface: { default: { hex: string } }
}

export class MatugenService {
  private configPath: string

  constructor() {
    this.configPath = `${GLib.get_home_dir()}/.config/matugen/config.toml`
  }

  async generateAndApplyColors(imagePath: string): Promise<MatugenColors | null> {
    try {
      // Validate matugen is available
      if (!await this.validateMatugen()) {
        throw new Error("Matugen not found in PATH")
      }

      // Generate colors with JSON output
      const result = await execAsync(`matugen image "${imagePath}" --json`)
      const colorsData = JSON.parse(result)

      if (!colorsData.colors) {
        throw new Error("Invalid matugen output format")
      }

      // Apply colors to templates (automatic via config)
      await execAsync(`matugen image "${imagePath}"`)

      // Reload applications
      await this.reloadApplications()

      return colorsData.colors as MatugenColors
    } catch (error) {
      console.error("Matugen color generation failed:", error)
      return null
    }
  }

  private async validateMatugen(): Promise<boolean> {
    try {
      await execAsync("which matugen")
      return true
    } catch {
      return false
    }
  }

  private async reloadApplications() {
    const reloadCommands = [
      'pkill -SIGUSR2 waybar',
      'hyprctl reload',
      'pkill -USR1 kitty'
    ]

    for (const cmd of reloadCommands) {
      try {
        await execAsync(['bash', '-c', cmd])
      } catch (error) {
        console.log(`Failed to reload with: ${cmd}`)
      }
    }
  }
} 