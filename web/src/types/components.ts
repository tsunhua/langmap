export interface ExpressionCardProps {
  expression: any
  showActions?: boolean
  showAudio?: boolean
}

export interface LanguageSelectorProps {
  modelValue?: string
  languages: any[]
  placeholder?: string
  disabled?: boolean
}

export interface ModalProps {
  isOpen: boolean
  title?: string
  size?: 'sm' | 'md' | 'lg' | 'xl'
}

export interface FormProps {
  modelValue: any
  schema?: any
  disabled?: boolean
}

export interface NotificationProps {
  type: 'success' | 'error' | 'warning' | 'info'
  message: string
  duration?: number
  onClose?: () => void
}
