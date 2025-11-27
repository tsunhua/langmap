import { createI18n } from 'vue-i18n'
import { fetchUITranslations, transformTranslations } from './services/languageService.js'

// Define static messages for default languages
const staticMessages = {
  en: {
    home: {
      title: 'Explore the World of Languages',
      subtitle: 'Discover how expressions vary across regions and cultures',
      searchPlaceholder: 'Search for an expression...',
      searchButton: 'Search',
      totalExpressions: 'Total Expressions',
      languages: 'Languages',
      regions: 'Regions',
      mapTitle: 'Global Language Distribution',
      mapDescription: 'Explore the richness of linguistic expressions across different regions. Larger circles indicate more expressions in that area.',
      expressionDensity: 'Expression Density',
      low: 'Low',
      medium: 'Medium',
      high: 'High',
      getStarted: 'Get Started',
      searchExpressions: 'Search Expressions',
      searchExpressionsDesc: 'Find how words and sentences are expressed across different languages and regions.',
      startSearching: 'Start Searching →',
      addExpression: 'Add Expression',
      addExpressionDesc: 'Contribute to our database by adding expressions from your language or region.',
      addNew: 'Add New →',
      exploreMap: 'Explore Map',
      exploreMapDesc: 'Visualize linguistic diversity on an interactive world map.',
      viewMap: 'View Map →',
      loadingMap: 'Loading map...'
    },
    nav: {
      home: 'Home',
      search: 'Search'
    },
    footer: {
      copyright: '© {year} langmap - Linguistic Expression Mapping Platform'
    },
    search: {
      title: 'Search Expressions',
      description: 'Find linguistic expressions across languages and regions',
      placeholder: 'Enter a word or sentence...',
      button: 'Search',
      searching: 'Searching expressions...',
      noResults: 'No results found',
      tryDifferent: 'Try different search terms or add a new expression',
      addExpression: 'Add "{expression}"',
      newExpression: 'new expression',
      foundExpressions: 'Found {count} expression{plural}',
      plural: 's'
    },
    create: {
      back: 'Back',
      title: 'Add New Expression',
      text: 'Text',
      textPlaceholder: 'Enter the linguistic expression',
      textHelp: 'The actual word or sentence in the language',
      language: 'Language (BCP-47)',
      languagePlaceholder: 'e.g. en, zh-CN, es-ES',
      languageHelp: 'Standard language code',
      region: 'Region (optional)',
      regionPlaceholder: 'e.g. China, Spain, Global',
      regionHelp: 'Geographic region or area',
      source: 'Source reference (optional)',
      sourcePlaceholder: 'e.g. Wiktionary, Dictionary.com, or a URL',
      sourceHelp: 'Origin or reference for this expression',
      submit: 'Create Expression',
      cancel: 'Cancel',
      requiredError: 'Language and text are required.'
    },
    detail: {
      backToSearch: 'Back to Search',
      loading: 'Loading expression details...',
      expressionDetails: 'Expression Details',
      associatedMeanings: 'Associated Meanings',
      associateExpressions: 'Associate Expressions',
      cancel: 'Cancel',
      searchPlaceholder: 'Search expressions to associate...',
      search: 'Search',
      searching: 'Searching...',
      noExpressionsFound: 'No expressions found. Try different search terms.',
      link: 'Link',
      alreadyLinked: 'Already linked',
      includesCurrent: 'Search results include the current expression.',
      linkToMeaning: 'Link to meaning:',
      selectMeaning: '-- Select meaning --',
      createNew: 'Create new meaning…',
      newMeaningGloss: 'New meaning gloss',
      createMeaning: 'Create Meaning',
      noMeanings: 'No meanings associated with this expression',
      associateWithMeanings: 'Associate with meanings'
    },
    expressionCard: {
      global: 'Global',
      play: 'Play',
      auto: 'auto'
    },
    versionHistory: {
      title: 'Version History',
      loading: 'Loading versions...',
      noVersions: 'No versions available',
      auto: 'auto',
      anonymous: 'Anonymous'
    }
  },
  'zh-CN': {
    home: {
      title: '探索世界语言',
      subtitle: '发现不同地区和文化中的表达方式',
      searchPlaceholder: '搜索词句...',
      searchButton: '搜索',
      totalExpressions: '总词句',
      languages: '语言',
      regions: '地区',
      mapTitle: '全球语言分布',
      mapDescription: '探索不同地区的语言词句丰富度。较大的圆圈表示该区域有更多的词句。',
      expressionDensity: '词句密度',
      low: '低',
      medium: '中',
      high: '高',
      getStarted: '开始使用',
      searchExpressions: '搜索词句',
      searchExpressionsDesc: '查找词句在不同语言和地区中的表达方式。',
      startSearching: '开始搜索 →',
      addExpression: '添加词句',
      addExpressionDesc: '通过添加您语言或地区的词句为我们的数据库做贡献。',
      addNew: '添加新词句 →',
      exploreMap: '探索地图',
      exploreMapDesc: '在交互式世界地图上可视化语言多样性。',
      viewMap: '查看地图 →',
      loadingMap: '加载地图中...'
    },
    nav: {
      home: '首页',
      search: '搜索'
    },
    footer: {
      copyright: '© {year} langmap - 语言表达映射平台'
    },
    search: {
      title: '搜索词句',
      description: '跨语言和地区查找语言词句',
      placeholder: '输入词句...',
      button: '搜索',
      searching: '正在搜索词句...',
      noResults: '未找到结果',
      tryDifferent: '尝试不同的搜索词或添加新词句',
      addExpression: '添加 "{expression}"',
      newExpression: '新词句',
      foundExpressions: '找到 {count} 个词句',
      plural: ''
    },
    create: {
      back: '返回',
      title: '添加新词句',
      text: '文本',
      textPlaceholder: '输入语言词句',
      textHelp: '语言中的实际词句',
      language: '语言 (BCP-47)',
      languagePlaceholder: '例如 en, zh-CN, es-ES',
      languageHelp: '标准语言代码',
      region: '地区 (可选)',
      regionPlaceholder: '例如 中国, 西班牙, 全球',
      regionHelp: '地理区域',
      source: '来源参考 (可选)',
      sourcePlaceholder: '例如 Wiktionary, Dictionary.com, 或 URL',
      sourceHelp: '此词句的来源或参考',
      submit: '创建词句',
      cancel: '取消',
      requiredError: '语言和文本是必填项。'
    },
    detail: {
      backToSearch: '返回搜索',
      loading: '正在加载词句详情...',
      expressionDetails: '词句详情',
      associatedMeanings: '关联含义',
      associateExpressions: '关联词句',
      cancel: '取消',
      searchPlaceholder: '搜索要关联的词句...',
      search: '搜索',
      searching: '搜索中...',
      noExpressionsFound: '未找到词句。请尝试不同的搜索词。',
      link: '链接',
      alreadyLinked: '已链接',
      includesCurrent: '搜索结果包含当前词句。',
      linkToMeaning: '链接到含义:',
      selectMeaning: '-- 选择含义 --',
      createNew: '创建新含义…',
      newMeaningGloss: '新含义词汇',
      createMeaning: '创建含义',
      noMeanings: '没有与此词句关联的含义',
      associateWithMeanings: '与含义关联'
    },
    expressionCard: {
      global: '全球',
      play: '播放',
      auto: '自动'
    },
    versionHistory: {
      title: '版本历史',
      loading: '正在加载版本...',
      noVersions: '无可用版本',
      auto: '自动',
      anonymous: '匿名'
    }
  },
  'zh-TW': {
    home: {
      title: '探索世界語言',
      subtitle: '發現不同地區和文化中的表達方式',
      searchPlaceholder: '搜尋詞句...',
      searchButton: '搜尋',
      totalExpressions: '總詞句',
      languages: '語言',
      regions: '地區',
      mapTitle: '全球語言分佈',
      mapDescription: '探索不同地區的語言詞句豐富度。較大的圓圈表示該區域有更多的詞句。',
      expressionDensity: '詞句密度',
      low: '低',
      medium: '中',
      high: '高',
      getStarted: '開始使用',
      searchExpressions: '搜尋詞句',
      searchExpressionsDesc: '尋找詞句在不同語言和地區中的表達方式。',
      startSearching: '開始搜尋 →',
      addExpression: '新增詞句',
      addExpressionDesc: '透過新增您語言或地區的詞句為我們的資料庫做貢獻。',
      addNew: '新增新詞句 →',
      exploreMap: '探索地圖',
      exploreMapDesc: '在互動式世界地圖上視覺化語言多樣性。',
      viewMap: '檢視地圖 →',
      loadingMap: '載入地圖中...'
    },
    nav: {
      home: '首頁',
      search: '搜尋'
    },
    footer: {
      copyright: '© {year} langmap - 語言表示對映平台'
    },
    search: {
      title: '搜尋詞句',
      description: '跨語言和地區尋找語言詞句',
      placeholder: '輸入詞句...',
      button: '搜尋',
      searching: '正在搜尋詞句...',
      noResults: '未找到結果',
      tryDifferent: '嘗試不同的搜尋詞或新增新詞句',
      addExpression: '新增 "{expression}"',
      newExpression: '新詞句',
      foundExpressions: '找到 {count} 個詞句',
      plural: ''
    },
    create: {
      back: '返回',
      title: '新增新詞句',
      text: '文字',
      textPlaceholder: '輸入語言詞句',
      textHelp: '語言中的實際詞句',
      language: '語言 (BCP-47)',
      languagePlaceholder: '例如 en, zh-TW, es-ES',
      languageHelp: '標準語言代碼',
      region: '地區 (可選)',
      regionPlaceholder: '例如 中國, 西班牙, 全球',
      regionHelp: '地理區域',
      source: '來源參考 (可選)',
      sourcePlaceholder: '例如 Wiktionary, Dictionary.com, 或 URL',
      sourceHelp: '此詞句的來源或參考',
      submit: '建立詞句',
      cancel: '取消',
      requiredError: '語言和文字是必填項。'
    },
    detail: {
      backToSearch: '返回搜尋',
      loading: '正在載入詞句詳情...',
      expressionDetails: '詞句詳情',
      associatedMeanings: '關聯含義',
      associateExpressions: '關聯詞句',
      cancel: '取消',
      searchPlaceholder: '搜尋要關聯的詞句...',
      search: '搜尋',
      searching: '搜尋中...',
      noExpressionsFound: '未找到詞句。請嘗試不同的搜尋詞。',
      link: '連結',
      alreadyLinked: '已連結',
      includesCurrent: '搜尋結果包含目前詞句。',
      linkToMeaning: '連結到含義:',
      selectMeaning: '-- 選擇含義 --',
      createNew: '建立新含義…',
      newMeaningGloss: '新含義詞彙',
      createMeaning: '建立含義',
      noMeanings: '沒有與此詞句關聯的含義',
      associateWithMeanings: '與含義關聯'
    },
    expressionCard: {
      global: '全球',
      play: '播放',
      auto: '自動'
    },
    versionHistory: {
      title: '版本歷史',
      loading: '正在載入版本...',
      noVersions: '無可用版本',
      auto: '自動',
      anonymous: '匿名'
    }
  },
  es: {
    home: {
      title: 'Explora el Mundo de los Idiomas',
      subtitle: 'Descubre cómo varían las expresiones en diferentes regiones y culturas',
      searchPlaceholder: 'Buscar una expresión...',
      searchButton: 'Buscar',
      totalExpressions: 'Expresiones Totales',
      languages: 'Idiomas',
      regions: 'Regiones',
      mapTitle: 'Distribución Lingüística Global',
      mapDescription: 'Explora la riqueza de expresiones lingüísticas en diferentes regiones. Los círculos más grandes indican más expresiones en esa área.',
      expressionDensity: 'Densidad de Expresiones',
      low: 'Baja',
      medium: 'Media',
      high: 'Alta',
      getStarted: 'Comenzar',
      searchExpressions: 'Buscar Expresiones',
      searchExpressionsDesc: 'Encuentra cómo se expresan palabras y oraciones en diferentes idiomas y regiones.',
      startSearching: 'Comenzar Búsqueda →',
      addExpression: 'Agregar Expresión',
      addExpressionDesc: 'Contribuye a nuestra base de datos agregando expresiones de tu idioma o región.',
      addNew: 'Agregar Nueva →',
      exploreMap: 'Explorar Mapa',
      exploreMapDesc: 'Visualiza la diversidad lingüística en un mapa mundial interactivo.',
      viewMap: 'Ver Mapa →',
      loadingMap: 'Cargando mapa...'
    },
    nav: {
      home: 'Inicio',
      search: 'Buscar'
    },
    footer: {
      copyright: '© {year} langmap - Plataforma de Mapeo de Expresiones Lingüísticas'
    },
    search: {
      title: 'Buscar Expresiones',
      description: 'Encuentra expresiones lingüísticas en diferentes idiomas y regiones',
      placeholder: 'Ingresa una palabra o oración...',
      button: 'Buscar',
      searching: 'Buscando expresiones...',
      noResults: 'No se encontraron resultados',
      tryDifferent: 'Prueba con términos de búsqueda diferentes o agrega una nueva expresión',
      addExpression: 'Agregar "{expression}"',
      newExpression: 'nueva expresión',
      foundExpressions: 'Se encontraron {count} expresión{plural}',
      plural: 'es'
    },
    create: {
      back: 'Atrás',
      title: 'Agregar Nueva Expresión',
      text: 'Texto',
      textPlaceholder: 'Ingresa la expresión lingüística',
      textHelp: 'La palabra o oración real en el idioma',
      language: 'Idioma (BCP-47)',
      languagePlaceholder: 'ej. en, zh-CN, es-ES',
      languageHelp: 'Código estándar de idioma',
      region: 'Región (opcional)',
      regionPlaceholder: 'ej. China, España, Global',
      regionHelp: 'Región geográfica o área',
      source: 'Referencia de fuente (opcional)',
      sourcePlaceholder: 'ej. Wiktionary, Dictionary.com, o una URL',
      sourceHelp: 'Origen o referencia para esta expresión',
      submit: 'Crear Expresión',
      cancel: 'Cancelar',
      requiredError: 'El idioma y el texto son obligatorios.'
    },
    detail: {
      backToSearch: 'Volver a la búsqueda',
      loading: 'Cargando detalles de la expresión...',
      expressionDetails: 'Detalles de la Expresión',
      associatedMeanings: 'Significados Asociados',
      associateExpressions: 'Asociar Expresiones',
      cancel: 'Cancelar',
      searchPlaceholder: 'Buscar expresiones para asociar...',
      search: 'Buscar',
      searching: 'Buscando...',
      noExpressionsFound: 'No se encontraron expresiones. Prueba con términos de búsqueda diferentes.',
      link: 'Enlazar',
      alreadyLinked: 'Ya enlazado',
      includesCurrent: 'Los resultados de búsqueda incluyen la expresión actual.',
      linkToMeaning: 'Enlazar al significado:',
      selectMeaning: '-- Seleccionar significado --',
      createNew: 'Crear nuevo significado…',
      newMeaningGloss: 'Glosa del nuevo significado',
      createMeaning: 'Crear Significado',
      noMeanings: 'No hay significados asociados con esta expresión',
      associateWithMeanings: 'Asociar con significados'
    },
    expressionCard: {
      global: 'Global',
      play: 'Reproducir',
      auto: 'auto'
    },
    versionHistory: {
      title: 'Historial de Versiones',
      loading: 'Cargando versiones...',
      noVersions: 'No hay versiones disponibles',
      auto: 'auto',
      anonymous: 'Anónimo'
    }
  },
  fr: {
    home: {
      title: 'Explorer le Monde des Langues',
      subtitle: 'Découvrez comment les expressions varient selon les régions et les cultures',
      searchPlaceholder: 'Rechercher une expression...',
      searchButton: 'Rechercher',
      totalExpressions: 'Expressions Totales',
      languages: 'Langues',
      regions: 'Régions',
      mapTitle: 'Distribution Linguistique Mondiale',
      mapDescription: 'Explorez la richesse des expressions linguistiques dans différentes régions. Les cercles plus grands indiquent davantage d\'expressions dans cette zone.',
      expressionDensity: 'Densité d\'Expressions',
      low: 'Faible',
      medium: 'Moyenne',
      high: 'Élevée',
      getStarted: 'Commencer',
      searchExpressions: 'Rechercher des Expressions',
      searchExpressionsDesc: 'Trouvez comment les mots et les phrases sont exprimés dans différentes langues et régions.',
      startSearching: 'Commencer la Recherche →',
      addExpression: 'Ajouter une Expression',
      addExpressionDesc: 'Contribuez à notre base de données en ajoutant des expressions de votre langue ou région.',
      addNew: 'Ajouter Nouvelle →',
      exploreMap: 'Explorer la Carte',
      exploreMapDesc: 'Visualisez la diversité linguistique sur une carte mondiale interactive.',
      viewMap: 'Voir la Carte →',
      loadingMap: 'Chargement de la carte...'
    },
    nav: {
      home: 'Accueil',
      search: 'Recherche'
    },
    footer: {
      copyright: '© {year} langmap - Plateforme de Cartographie des Expressions Linguistiques'
    },
    search: {
      title: 'Rechercher des Expressions',
      description: 'Trouvez des expressions linguistiques dans différentes langues et régions',
      placeholder: 'Entrez un mot ou une phrase...',
      button: 'Rechercher',
      searching: 'Recherche d\'expressions...',
      noResults: 'Aucun résultat trouvé',
      tryDifferent: 'Essayez des termes de recherche différents ou ajoutez une nouvelle expression',
      addExpression: 'Ajouter "{expression}"',
      newExpression: 'nouvelle expression',
      foundExpressions: 'Trouvé {count} expression{plural}',
      plural: 's'
    },
    create: {
      back: 'Retour',
      title: 'Ajouter une Nouvelle Expression',
      text: 'Texte',
      textPlaceholder: 'Entrez l\'expression linguistique',
      textHelp: 'Le mot ou la phrase réelle dans la langue',
      language: 'Langue (BCP-47)',
      languagePlaceholder: 'ex. en, zh-CN, es-ES',
      languageHelp: 'Code de langue standard',
      region: 'Région (facultatif)',
      regionPlaceholder: 'ex. Chine, Espagne, Global',
      regionHelp: 'Région géographique ou zone',
      source: 'Référence de source (facultatif)',
      sourcePlaceholder: 'ex. Wiktionary, Dictionary.com, ou une URL',
      sourceHelp: 'Origine ou référence pour cette expression',
      submit: 'Créer l\'Expression',
      cancel: 'Annuler',
      requiredError: 'La langue et le texte sont requis.'
    },
    detail: {
      backToSearch: 'Retour à la recherche',
      loading: 'Chargement des détails de l\'expression...',
      expressionDetails: 'Détails de l\'Expression',
      associatedMeanings: 'Significations Associées',
      associateExpressions: 'Associer des Expressions',
      cancel: 'Annuler',
      searchPlaceholder: 'Rechercher des expressions à associer...',
      search: 'Rechercher',
      searching: 'Recherche en cours...',
      noExpressionsFound: 'Aucune expression trouvée. Essayez des termes de recherche différents.',
      link: 'Lier',
      alreadyLinked: 'Déjà lié',
      includesCurrent: 'Les résultats de recherche incluent l\'expression actuelle.',
      linkToMeaning: 'Lier à la signification:',
      selectMeaning: '-- Sélectionner une signification --',
      createNew: 'Créer une nouvelle signification…',
      newMeaningGloss: 'Glose de la nouvelle signification',
      createMeaning: 'Créer une Signification',
      noMeanings: 'Aucune signification associée à cette expression',
      associateWithMeanings: 'Associer avec des significations'
    },
    expressionCard: {
      global: 'Global',
      play: 'Jouer',
      auto: 'auto'
    },
    versionHistory: {
      title: 'Historique des Versions',
      loading: 'Chargement des versions...',
      noVersions: 'Aucune version disponible',
      auto: 'auto',
      anonymous: 'Anonyme'
    }
  },
  ja: {
    home: {
      title: '世界の言語を探索する',
      subtitle: '地域や文化によって表現方法がどのように異なるかを発見する',
      searchPlaceholder: '表現を検索...',
      searchButton: '検索',
      totalExpressions: '総表現数',
      languages: '言語',
      regions: '地域',
      mapTitle: 'グローバル言語分布',
      mapDescription: 'さまざまな地域における言語表現の豊かさを探求します。大きな円はその地域の表現が多いことを示します。',
      expressionDensity: '表現密度',
      low: '低',
      medium: '中',
      high: '高',
      getStarted: '始めましょう',
      searchExpressions: '表現を検索',
      searchExpressionsDesc: 'さまざまな言語や地域で単語や文がどのように表現されているかを見つけます。',
      startSearching: '検索開始 →',
      addExpression: '表現を追加',
      addExpressionDesc: 'あなたの言語や地域からの表現を追加してデータベースに貢献してください。',
      addNew: '新規追加 →',
      exploreMap: '地図を探索',
      exploreMapDesc: 'インタラクティブな世界地図で言語の多様性を可視化します。',
      viewMap: '地図を表示 →',
      loadingMap: '地図を読み込み中...'
    },
    nav: {
      home: 'ホーム',
      search: '検索'
    },
    footer: {
      copyright: '© {year} langmap - 言語表現マッピングプラットフォーム'
    },
    search: {
      title: '表現を検索',
      description: '言語や地域にまたがる言語表現を見つける',
      placeholder: '単語や文を入力...',
      button: '検索',
      searching: '表現を検索中...',
      noResults: '結果が見つかりません',
      tryDifferent: '別の検語を試すか、新しい表現を追加してください',
      addExpression: '"{expression}" を追加',
      newExpression: '新しい表現',
      foundExpressions: '{count} 件の表現が見つかりました',
      plural: ''
    },
    create: {
      back: '戻る',
      title: '新しい表現を追加',
      text: 'テキスト',
      textPlaceholder: '言語表現を入力',
      textHelp: '言語における実際の単語や文',
      language: '言語 (BCP-47)',
      languagePlaceholder: '例: en, zh-CN, es-ES',
      languageHelp: '標準言語コード',
      region: '地域 (任意)',
      regionPlaceholder: '例: 中国, スペイン, グローバル',
      regionHelp: '地理的地域またはエリア',
      source: 'ソース参照 (任意)',
      sourcePlaceholder: '例: Wiktionary, Dictionary.com, またはURL',
      sourceHelp: 'この表現の出典または参照',
      submit: '表現を作成',
      cancel: 'キャンセル',
      requiredError: '言語とテキストは必須です。'
    },
    detail: {
      backToSearch: '検索に戻る',
      loading: '表現の詳細を読み込み中...',
      expressionDetails: '表現の詳細',
      associatedMeanings: '関連する意味',
      associateExpressions: '表現を関連付ける',
      cancel: 'キャンセル',
      searchPlaceholder: '関連付ける表現を検索...',
      search: '検索',
      searching: '検索中...',
      noExpressionsFound: '表現が見つかりません。別の検索語を試してください。',
      link: 'リンク',
      alreadyLinked: 'すでにリンク済み',
      includesCurrent: '検索結果に現在の表現が含まれています。',
      linkToMeaning: '意味にリンク:',
      selectMeaning: '-- 意味を選択 --',
      createNew: '新しい意味を作成…',
      newMeaningGloss: '新しい意味の語彙',
      createMeaning: '意味を作成',
      noMeanings: 'この表現に関連する意味はありません',
      associateWithMeanings: '意味と関連付ける'
    },
    expressionCard: {
      global: 'グローバル',
      play: '再生',
      auto: '自動'
    },
    versionHistory: {
      title: 'バージョン履歴',
      loading: 'バージョンを読み込み中...',
      noVersions: '利用可能なバージョンがありません',
      auto: '自動',
      anonymous: '匿名'
    }
  }
}

// Cache for dynamically loaded messages
const dynamicMessagesCache = {}

// Create i18n instance
const i18n = createI18n({
  legacy: false, // Use Composition API mode
  locale: 'en', // Default language
  fallbackLocale: 'en', // Fallback language
  messages: staticMessages
})

/**
 * Load UI translations for a given language dynamically
 * @param {string} languageCode - The language code to load translations for
 */
export async function loadLanguage(languageCode) {
  // If it's a static language, no need to fetch anything
  if (staticMessages[languageCode]) {
    return
  }

  // Check if we have cached messages
  if (dynamicMessagesCache[languageCode]) {
    i18n.global.setLocaleMessage(languageCode, dynamicMessagesCache[languageCode])
    return
  }

  try {
    // Fetch UI translations from backend
    const translations = await fetchUITranslations(languageCode)
    
    // Transform to nested object format
    const messages = transformTranslations(translations)
    
    // Cache the messages
    dynamicMessagesCache[languageCode] = messages
    
    // Set the locale messages
    i18n.global.setLocaleMessage(languageCode, messages)
  } catch (error) {
    console.error(`Failed to load translations for language ${languageCode}:`, error)
    // Fall back to English if failed to load
    i18n.global.setLocaleMessage(languageCode, staticMessages.en)
  }
}

export default i18n