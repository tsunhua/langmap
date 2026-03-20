# LangMap Components

This directory contains reusable Vue 3 components for the LangMap application.

## Component Structure

Components are organized by functionality. Each component is self-contained with its own styling and logic.

---

## 📚 Components

### Core Components

#### ExpressionCard.vue
**Purpose**: Display expression information in a card format with language, region, and audio playback support.

**Features**:
- Displays expression text and language
- Shows region information with map icon
- Audio playback controls
- Edit and delete actions (for authenticated users)
- Clickable card to navigate to detail page

**Props**:
- `item` (Expression): The expression data to display
- `showAudio` (Boolean): Whether to show audio player (default: true)
- `compact` (Boolean): Compact display mode (default: false)

**Events**:
- `edit`: Emitted when edit button is clicked
- `delete`: Emitted when delete button is clicked

**Usage**:
```vue
<ExpressionCard
  :item="expression"
  :show-audio="true"
  @edit="handleEdit"
  @delete="handleDelete"
/>
```

---

#### AudioRecorder.vue
**Purpose**: Record and manage audio recordings for expressions using the Web Audio API.

**Features**:
- Record audio from microphone
- Preview recorded audio
- Delete recordings
- Upload to server
- Visual feedback for recording state

**Props**:
- `expressionId` (Number): The expression ID to associate audio with
- `initialAudio` (String): Existing audio URL

**Events**:
- `upload-complete`: Emitted when audio upload is complete
- `error`: Emitted when an error occurs

**Usage**:
```vue
<AudioRecorder
  :expression-id="123"
  :initial-audio="existingAudioUrl"
  @upload-complete="handleUploadComplete"
  @error="handleError"
/>
```

---

#### CreateExpression.vue
**Purpose**: Form for creating new expressions with batch support.

**Features**:
- Single expression creation
- Batch expression creation
- Language and region selection
- Meaning association
- Form validation

**Props**:
- `batchMode` (Boolean): Enable batch mode (default: false)

**Events**:
- `created`: Emitted when expression(s) are created successfully
- `cancel`: Emitted when form is cancelled

**Usage**:
```vue
<CreateExpression
  :batch-mode="true"
  @created="handleCreated"
  @cancel="handleCancel"
/>
```

---

#### SmartSearch.vue
**Purpose**: Advanced search functionality with filters and suggestions.

**Features**:
- Real-time search
- Language filter
- Region filter
- Search suggestions
- History tracking

**Props**:
- `placeholder` (String): Input placeholder text (default: "Search expressions...")
- `showFilters` (Boolean): Show filter options (default: true)

**Events**:
- `search`: Emitted when search is triggered
- `filter-change`: Emitted when filters change

**Usage**:
```vue
<SmartSearch
  placeholder="Find expressions..."
  :show-filters="true"
  @search="handleSearch"
  @filter-change="handleFilterChange"
/>
```

---

### Modal Components

#### AddLanguageModal.vue
**Purpose**: Modal dialog for adding new languages to the system.

**Features**:
- Language name input
- Language code input
- ISO 639-1/639-2 code validation
- Form validation

**Events**:
- `submit`: Emitted when language is submitted
- `close`: Emitted when modal is closed

**Usage**:
```vue
<AddLanguageModal
  @submit="handleAddLanguage"
  @close="closeModal"
/>
```

---

#### AddToCollectionModal.vue
**Purpose**: Modal for adding expressions to collections.

**Features**:
- Collection selection
- Create new collection
- Batch add multiple expressions

**Props**:
- `expressionIds` (Array): Array of expression IDs to add

**Events**:
- `added`: Emitted when expressions are added to collection
- `close`: Emitted when modal is closed

**Usage**:
```vue
<AddToCollectionModal
  :expression-ids="[1, 2, 3]"
  @added="handleAdded"
  @close="closeModal"
/>
```

---

#### ExpressionGroupModal.vue
**Purpose**: Modal for grouping multiple expressions together (associating with meanings).

**Features**:
- Expression selection
- Grouping configuration
- Meaning assignment

**Props**:
- `expressionIds` (Array): Array of expression IDs to group

**Events**:
- `grouped`: Emitted when expressions are grouped
- `close`: Emitted when modal is closed

**Usage**:
```vue
<ExpressionGroupModal
  :expression-ids="[1, 2, 3]"
  @grouped="handleGrouped"
  @close="closeModal"
/>
```

---

### Advanced Components

#### FloatingExpressions.vue
**Purpose**: Floating panel for quick expression creation and management.

**Features**:
- Quick add expressions
- Quick search
- Collapsible panel
- Position customization

**Props**:
- `position` (String): Position of panel ('top-left', 'top-right', 'bottom-left', 'bottom-right')

**Events**:
- `create`: Emitted when expression is created
- `search`: Emitted when search is triggered

**Usage**:
```vue
<FloatingExpressions
  position="bottom-right"
  @create="handleCreate"
  @search="handleSearch"
/>
```

---

#### DynamicLanguageDemo.vue
**Purpose**: Demonstration component for dynamic language switching and translation features.

**Features**:
- Dynamic language switching
- Real-time translation preview
- Language comparison

**Usage**:
```vue
<DynamicLanguageDemo />
```

---

#### VersionHistory.vue
**Purpose**: Display version history for expressions.

**Features**:
- Timeline view of changes
- Version diff viewer
- Rollback functionality

**Props**:
- `expressionId` (Number): The expression ID to show history for

**Usage**:
```vue
<VersionHistory :expression-id="123" />
```

---

## 🎨 Styling

All components use **Tailwind CSS** for styling with consistent design tokens:

- **Colors**: Slate color palette for neutral elements
- **Typography**: Default system fonts with clear hierarchy
- **Spacing**: Consistent spacing scale (4px base unit)
- **Rounding**: Rounded corners (rounded-lg, rounded-full)
- **Shadows**: Subtle shadows for depth

---

## 🧩 Component Guidelines

### Creating New Components

1. **Naming**: Use PascalCase for component files (e.g., `MyComponent.vue`)

2. **Props**: Define props with types and default values:
```vue
<script setup>
const props = defineProps<{
  title: string
  count?: number
}>()

const props = withDefaults(defineProps<{
  title: string
  count?: number
}>(), {
  count: 0
})
</script>
```

3. **Events**: Define events with clear naming:
```vue
<script setup>
const emit = defineEmits<{
  'update:modelValue': [value: string]
  'submit': [data: FormData]
}>()
</script>
```

4. **Composition**: Prefer Composition API with `<script setup>`

5. **TypeScript**: Use TypeScript for type safety

6. **Accessibility**: Include proper ARIA attributes and keyboard support

### Best Practices

- Keep components focused on a single responsibility
- Use composables for reusable logic
- Emulate component communication via props and events
- Avoid direct DOM manipulation
- Use Vue's reactivity system properly
- Test components in isolation
- Document complex interactions

---

## 📦 Dependencies

Components may use:

- **Vue 3**: Framework
- **Vue Router**: Routing
- **Pinia**: State management
- **Tailwind CSS**: Styling
- **i18n**: Internationalization

---

## 🔧 Development

### Running Components

Components are used throughout the application. To view them:

1. Start the development server: `npm run dev`
2. Navigate to pages that use the component

### Testing Components

Test components using Vue Test Utils:

```bash
npm run test:unit
```

---

## 📝 Contributing

When adding or modifying components:

1. Follow the existing code style
2. Add TypeScript types
3. Include JSDoc comments for complex logic
4. Test thoroughly
5. Update this README if component API changes

---

## 🐛 Issues

Report issues with components in the project issue tracker with:
- Component name
- Steps to reproduce
- Expected behavior
- Actual behavior
- Screenshots if applicable

---

**Last Updated**: 2026-03-18
