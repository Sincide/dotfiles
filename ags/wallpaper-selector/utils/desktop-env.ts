import { exec } from 'astal'

export function detectDesktopEnvironment(): string {
  const methods = [
    () => exec('echo $XDG_CURRENT_DESKTOP').trim(),
    () => exec('echo $DESKTOP_SESSION').trim(),
    () => exec('echo $XDG_SESSION_DESKTOP').trim()
  ]
  
  for (const method of methods) {
    try {
      const result = method()
      if (result && result !== '') {
        return result.toLowerCase()
      }
    } catch (error) {
      continue
    }
  }
  
  return 'unknown'
} 