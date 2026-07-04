// strings.dart
//
// UI string table for the 6 supported languages (en, hi, zh, es, fr, pt).
// Mirrors the scope of the web app's i18n.js. If reference/resilience-suite/i18n.js is provided,
// replace these values with the verbatim strings from it.
//
// NOTE: hi/zh/es/fr/pt strings are solid working translations but should get a native-speaker pass
// before the final demo. The product name "Resilience Compass" stays untranslated (brand).

class AppStrings {
  final String appTitle;
  final String appSubtitle;
  final String offlineBadge;

  // Setup
  final String setupWelcome;
  final String chooseLanguage;
  final String chooseJurisdictions;
  final String jurisdictionHint;
  final String isoAlwaysOn;
  final String loadModel;
  final String loadingModel;
  final String modelReady;
  final String start;
  final String continueLabel;
  final String retry;
  final String modelLoadError;

  // Navigation
  final String tabAssistant;
  final String tabScanner;
  final String menuAbout;

  // Assistant
  final String assistantTitle;
  final String assistantIntro;
  final String pillarProgress; // template with {n} and {total}
  final String answerHint;
  final String send;
  final String maturityLabel;
  final String nextPillar;
  final String skip;
  final String assessing;
  final String assessmentComplete;
  final String overallReadiness;

  // Scanner
  final String scannerTitle;
  final String scannerIntro;
  final String incidentHint;
  final String analyze;
  final String analyzing;
  final String category;
  final String severity;
  final String impactArea;
  final String resilienceScore;
  final String likelihood;
  final String controlMaturity;
  final String low;
  final String medium;
  final String high;

  // About
  final String aboutTitle;
  final String privacyNote;
  final String disclaimerTitle;

  // Tools panel (optional — English defaults so a missing translation never breaks the build).
  final String tabTools;
  final String toolsIntro;
  final String impactToleranceTitle;
  final String nthPartyTitle;
  final String serviceName;
  final String vendorName;
  final String serviceProvided;
  final String nthPartiesLabel;
  final String add;
  final String concentrationRisk;
  final String sharedByVendors;
  final String noConcentrationRisk;
  final String emptyTolerance;
  final String emptyVendors;

  const AppStrings({
    required this.appTitle,
    required this.appSubtitle,
    required this.offlineBadge,
    required this.setupWelcome,
    required this.chooseLanguage,
    required this.chooseJurisdictions,
    required this.jurisdictionHint,
    required this.isoAlwaysOn,
    required this.loadModel,
    required this.loadingModel,
    required this.modelReady,
    required this.start,
    required this.continueLabel,
    required this.retry,
    required this.modelLoadError,
    required this.tabAssistant,
    required this.tabScanner,
    required this.menuAbout,
    required this.assistantTitle,
    required this.assistantIntro,
    required this.pillarProgress,
    required this.answerHint,
    required this.send,
    required this.maturityLabel,
    required this.nextPillar,
    required this.skip,
    required this.assessing,
    required this.assessmentComplete,
    required this.overallReadiness,
    required this.scannerTitle,
    required this.scannerIntro,
    required this.incidentHint,
    required this.analyze,
    required this.analyzing,
    required this.category,
    required this.severity,
    required this.impactArea,
    required this.resilienceScore,
    required this.likelihood,
    required this.controlMaturity,
    required this.low,
    required this.medium,
    required this.high,
    required this.aboutTitle,
    required this.privacyNote,
    required this.disclaimerTitle,
    this.tabTools = 'Tools',
    this.toolsIntro =
        'Configure impact tolerances and map Nth-party dependencies. This data grounds the Assistant’s Tolerance and Third-Party pillars.',
    this.impactToleranceTitle = 'Impact Tolerance Configurator',
    this.nthPartyTitle = 'Nth-Party Dependency Mapper',
    this.serviceName = 'Critical service',
    this.vendorName = 'Vendor',
    this.serviceProvided = 'Service provided',
    this.nthPartiesLabel = 'Nth-party dependencies (comma-separated)',
    this.add = 'Add',
    this.concentrationRisk = 'Concentration risk',
    this.sharedByVendors = 'shared by {n} vendors',
    this.noConcentrationRisk = 'No shared Nth-party dependencies detected.',
    this.emptyTolerance = 'No critical services configured yet.',
    this.emptyVendors = 'No vendors mapped yet.',
  });

  /// Fills the {n}/{total} template, e.g. "Pillar 3 of 10".
  String pillarProgressLabel(int n, int total) =>
      pillarProgress.replaceAll('{n}', '$n').replaceAll('{total}', '$total');

  String sharedByVendorsLabel(int n) => sharedByVendors.replaceAll('{n}', '$n');
}

/// The English display name of each supported language, keyed by code (for the picker).
const Map<String, String> kLanguageNames = {
  'en': 'English',
  'hi': 'हिन्दी',
  'zh': '简体中文',
  'es': 'Español',
  'fr': 'Français',
  'pt': 'Português',
};

/// The autonym the assistant should reply in — used inside the system prompt so Gemma answers
/// in the selected language regardless of the input language.
const Map<String, String> kLanguageReplyName = {
  'en': 'English',
  'hi': 'Hindi (हिन्दी)',
  'zh': 'Simplified Chinese (简体中文)',
  'es': 'Spanish (Español)',
  'fr': 'French (Français)',
  'pt': 'Portuguese (Português)',
};

const Map<String, AppStrings> kStrings = {
  'en': AppStrings(
    appTitle: 'Resilience Compass',
    appSubtitle: 'On-device operational resilience',
    offlineBadge: 'Offline · On-device',
    setupWelcome: 'Set up your assessment',
    chooseLanguage: 'Language',
    chooseJurisdictions: 'Regulatory jurisdictions',
    jurisdictionHint: 'Select all that apply. ISO 22301 is always included as the baseline.',
    isoAlwaysOn: 'Baseline · always on',
    loadModel: 'Load on-device model',
    loadingModel: 'Loading model…',
    modelReady: 'Model ready — runs fully offline',
    start: 'Start',
    continueLabel: 'Continue',
    retry: 'Retry',
    modelLoadError: 'Could not load the model. Check the model file and try again.',
    tabAssistant: 'Assistant',
    tabScanner: 'Scanner',
    menuAbout: 'About',
    assistantTitle: 'BCM Assistant',
    assistantIntro: 'A guided self-assessment across 10 resilience pillars. Answer in your own words, or ask a question at any time.',
    pillarProgress: 'Pillar {n} of {total}',
    answerHint: 'Describe your current practice — or ask a question…',
    send: 'Send',
    maturityLabel: 'Maturity',
    nextPillar: 'Next pillar',
    skip: 'Skip',
    assessing: 'Assessing…',
    assessmentComplete: 'Assessment complete',
    overallReadiness: 'Overall readiness',
    scannerTitle: 'Incident Scanner',
    scannerIntro: 'Paste or describe an operational incident. Gemma classifies it on-device and scores resilience.',
    incidentHint: 'Paste or describe the incident…',
    analyze: 'Analyze',
    analyzing: 'Analyzing…',
    category: 'Category',
    severity: 'Severity',
    impactArea: 'Impact area',
    resilienceScore: 'Resilience score',
    likelihood: 'Likelihood',
    controlMaturity: 'Control maturity',
    low: 'Low',
    medium: 'Medium',
    high: 'High',
    aboutTitle: 'About & Privacy',
    privacyNote: 'All processing happens on this device. Your inputs, chats and registers never leave your phone.',
    disclaimerTitle: 'Compliance disclaimer',
  ),
  'hi': AppStrings(
    appTitle: 'Resilience Compass',
    appSubtitle: 'डिवाइस पर परिचालन लचीलापन',
    offlineBadge: 'ऑफ़लाइन · डिवाइस पर',
    setupWelcome: 'अपना आकलन सेट करें',
    chooseLanguage: 'भाषा',
    chooseJurisdictions: 'नियामक क्षेत्राधिकार',
    jurisdictionHint: 'जो लागू हों उन्हें चुनें। ISO 22301 हमेशा आधार के रूप में शामिल रहता है।',
    isoAlwaysOn: 'आधार · हमेशा सक्रिय',
    loadModel: 'डिवाइस मॉडल लोड करें',
    loadingModel: 'मॉडल लोड हो रहा है…',
    modelReady: 'मॉडल तैयार — पूरी तरह ऑफ़लाइन चलता है',
    start: 'शुरू करें',
    continueLabel: 'जारी रखें',
    retry: 'पुनः प्रयास करें',
    modelLoadError: 'मॉडल लोड नहीं हो सका। मॉडल फ़ाइल जाँचें और पुनः प्रयास करें।',
    tabAssistant: 'सहायक',
    tabScanner: 'स्कैनर',
    menuAbout: 'परिचय',
    assistantTitle: 'BCM सहायक',
    assistantIntro: '10 लचीलापन स्तंभों में एक निर्देशित स्व-आकलन। अपने शब्दों में उत्तर दें, या कभी भी प्रश्न पूछें।',
    pillarProgress: 'स्तंभ {n} / {total}',
    answerHint: 'अपनी वर्तमान प्रथा बताएं — या प्रश्न पूछें…',
    send: 'भेजें',
    maturityLabel: 'परिपक्वता',
    nextPillar: 'अगला स्तंभ',
    skip: 'छोड़ें',
    assessing: 'आकलन हो रहा है…',
    assessmentComplete: 'आकलन पूर्ण',
    overallReadiness: 'समग्र तैयारी',
    scannerTitle: 'घटना स्कैनर',
    scannerIntro: 'किसी परिचालन घटना को चिपकाएँ या वर्णित करें। Gemma इसे डिवाइस पर वर्गीकृत करता है और लचीलापन अंक देता है।',
    incidentHint: 'घटना चिपकाएँ या वर्णन करें…',
    analyze: 'विश्लेषण करें',
    analyzing: 'विश्लेषण हो रहा है…',
    category: 'श्रेणी',
    severity: 'गंभीरता',
    impactArea: 'प्रभाव क्षेत्र',
    resilienceScore: 'लचीलापन अंक',
    likelihood: 'संभावना',
    controlMaturity: 'नियंत्रण परिपक्वता',
    low: 'निम्न',
    medium: 'मध्यम',
    high: 'उच्च',
    aboutTitle: 'परिचय और गोपनीयता',
    privacyNote: 'सभी प्रसंस्करण इसी डिवाइस पर होता है। आपके इनपुट, चैट और रजिस्टर कभी आपके फ़ोन से बाहर नहीं जाते।',
    disclaimerTitle: 'अनुपालन अस्वीकरण',
    tabTools: 'उपकरण',
    toolsIntro: 'प्रभाव सहनशीलता कॉन्फ़िगर करें और Nth-पक्ष निर्भरताएँ मैप करें। यह डेटा सहायक के सहनशीलता और तृतीय-पक्ष स्तंभों को आधार देता है।',
    impactToleranceTitle: 'प्रभाव सहनशीलता कॉन्फ़िगरेटर',
    nthPartyTitle: 'Nth-पक्ष निर्भरता मैपर',
    serviceName: 'महत्वपूर्ण सेवा',
    vendorName: 'विक्रेता',
    serviceProvided: 'प्रदान की गई सेवा',
    nthPartiesLabel: 'Nth-पक्ष निर्भरताएँ (अल्पविराम से अलग)',
    add: 'जोड़ें',
    concentrationRisk: 'संकेंद्रण जोखिम',
    sharedByVendors: '{n} विक्रेताओं द्वारा साझा',
    noConcentrationRisk: 'कोई साझा Nth-पक्ष निर्भरता नहीं मिली।',
    emptyTolerance: 'अभी तक कोई महत्वपूर्ण सेवा कॉन्फ़िगर नहीं की गई।',
    emptyVendors: 'अभी तक कोई विक्रेता मैप नहीं किया गया।',
  ),
  'zh': AppStrings(
    appTitle: 'Resilience Compass',
    appSubtitle: '设备端运营韧性',
    offlineBadge: '离线 · 设备端',
    setupWelcome: '设置您的评估',
    chooseLanguage: '语言',
    chooseJurisdictions: '监管辖区',
    jurisdictionHint: '选择所有适用项。ISO 22301 始终作为基准包含在内。',
    isoAlwaysOn: '基准 · 始终启用',
    loadModel: '加载设备端模型',
    loadingModel: '正在加载模型…',
    modelReady: '模型就绪 — 完全离线运行',
    start: '开始',
    continueLabel: '继续',
    retry: '重试',
    modelLoadError: '无法加载模型。请检查模型文件后重试。',
    tabAssistant: '助手',
    tabScanner: '扫描器',
    menuAbout: '关于',
    assistantTitle: 'BCM 助手',
    assistantIntro: '在 10 个韧性支柱上进行引导式自我评估。用您自己的话回答，或随时提问。',
    pillarProgress: '支柱 {n} / {total}',
    answerHint: '描述您目前的做法 — 或提出问题…',
    send: '发送',
    maturityLabel: '成熟度',
    nextPillar: '下一支柱',
    skip: '跳过',
    assessing: '正在评估…',
    assessmentComplete: '评估完成',
    overallReadiness: '整体准备度',
    scannerTitle: '事件扫描器',
    scannerIntro: '粘贴或描述一个运营事件。Gemma 在设备端对其分类并给出韧性评分。',
    incidentHint: '粘贴或描述事件…',
    analyze: '分析',
    analyzing: '正在分析…',
    category: '类别',
    severity: '严重程度',
    impactArea: '影响领域',
    resilienceScore: '韧性评分',
    likelihood: '可能性',
    controlMaturity: '控制成熟度',
    low: '低',
    medium: '中',
    high: '高',
    aboutTitle: '关于与隐私',
    privacyNote: '所有处理都在本设备上进行。您的输入、对话和登记簿绝不会离开您的手机。',
    disclaimerTitle: '合规免责声明',
    tabTools: '工具',
    toolsIntro: '配置影响容忍度并映射第 N 方依赖。这些数据将为助手的容忍度与第三方支柱提供依据。',
    impactToleranceTitle: '影响容忍度配置器',
    nthPartyTitle: '第 N 方依赖映射器',
    serviceName: '关键服务',
    vendorName: '供应商',
    serviceProvided: '提供的服务',
    nthPartiesLabel: '第 N 方依赖（用逗号分隔）',
    add: '添加',
    concentrationRisk: '集中度风险',
    sharedByVendors: '由 {n} 家供应商共用',
    noConcentrationRisk: '未检测到共用的第 N 方依赖。',
    emptyTolerance: '尚未配置关键服务。',
    emptyVendors: '尚未映射供应商。',
  ),
  'es': AppStrings(
    appTitle: 'Resilience Compass',
    appSubtitle: 'Resiliencia operativa en el dispositivo',
    offlineBadge: 'Sin conexión · En el dispositivo',
    setupWelcome: 'Configura tu evaluación',
    chooseLanguage: 'Idioma',
    chooseJurisdictions: 'Jurisdicciones regulatorias',
    jurisdictionHint: 'Selecciona todas las que apliquen. ISO 22301 siempre se incluye como base.',
    isoAlwaysOn: 'Base · siempre activa',
    loadModel: 'Cargar modelo en el dispositivo',
    loadingModel: 'Cargando modelo…',
    modelReady: 'Modelo listo — funciona totalmente sin conexión',
    start: 'Comenzar',
    continueLabel: 'Continuar',
    retry: 'Reintentar',
    modelLoadError: 'No se pudo cargar el modelo. Verifica el archivo del modelo e inténtalo de nuevo.',
    tabAssistant: 'Asistente',
    tabScanner: 'Escáner',
    menuAbout: 'Acerca de',
    assistantTitle: 'Asistente BCM',
    assistantIntro: 'Una autoevaluación guiada por los 10 pilares de resiliencia. Responde con tus palabras o haz una pregunta en cualquier momento.',
    pillarProgress: 'Pilar {n} de {total}',
    answerHint: 'Describe tu práctica actual — o haz una pregunta…',
    send: 'Enviar',
    maturityLabel: 'Madurez',
    nextPillar: 'Siguiente pilar',
    skip: 'Omitir',
    assessing: 'Evaluando…',
    assessmentComplete: 'Evaluación completa',
    overallReadiness: 'Preparación general',
    scannerTitle: 'Escáner de incidentes',
    scannerIntro: 'Pega o describe un incidente operativo. Gemma lo clasifica en el dispositivo y calcula la resiliencia.',
    incidentHint: 'Pega o describe el incidente…',
    analyze: 'Analizar',
    analyzing: 'Analizando…',
    category: 'Categoría',
    severity: 'Severidad',
    impactArea: 'Área de impacto',
    resilienceScore: 'Puntuación de resiliencia',
    likelihood: 'Probabilidad',
    controlMaturity: 'Madurez del control',
    low: 'Baja',
    medium: 'Media',
    high: 'Alta',
    aboutTitle: 'Acerca de y privacidad',
    privacyNote: 'Todo el procesamiento ocurre en este dispositivo. Tus entradas, chats y registros nunca salen de tu teléfono.',
    disclaimerTitle: 'Aviso de cumplimiento',
    tabTools: 'Herramientas',
    toolsIntro: 'Configura las tolerancias de impacto y mapea las dependencias de N-ésima parte. Estos datos fundamentan los pilares de Tolerancia y Terceros del Asistente.',
    impactToleranceTitle: 'Configurador de tolerancia de impacto',
    nthPartyTitle: 'Mapeador de dependencias de N-ésima parte',
    serviceName: 'Servicio crítico',
    vendorName: 'Proveedor',
    serviceProvided: 'Servicio prestado',
    nthPartiesLabel: 'Dependencias de N-ésima parte (separadas por comas)',
    add: 'Añadir',
    concentrationRisk: 'Riesgo de concentración',
    sharedByVendors: 'compartida por {n} proveedores',
    noConcentrationRisk: 'No se detectaron dependencias de N-ésima parte compartidas.',
    emptyTolerance: 'Aún no hay servicios críticos configurados.',
    emptyVendors: 'Aún no hay proveedores mapeados.',
  ),
  'fr': AppStrings(
    appTitle: 'Resilience Compass',
    appSubtitle: 'Résilience opérationnelle sur l’appareil',
    offlineBadge: 'Hors ligne · Sur l’appareil',
    setupWelcome: 'Configurez votre évaluation',
    chooseLanguage: 'Langue',
    chooseJurisdictions: 'Juridictions réglementaires',
    jurisdictionHint: 'Sélectionnez toutes celles qui s’appliquent. ISO 22301 est toujours incluse comme référence.',
    isoAlwaysOn: 'Référence · toujours active',
    loadModel: 'Charger le modèle sur l’appareil',
    loadingModel: 'Chargement du modèle…',
    modelReady: 'Modèle prêt — fonctionne entièrement hors ligne',
    start: 'Commencer',
    continueLabel: 'Continuer',
    retry: 'Réessayer',
    modelLoadError: 'Impossible de charger le modèle. Vérifiez le fichier du modèle et réessayez.',
    tabAssistant: 'Assistant',
    tabScanner: 'Scanner',
    menuAbout: 'À propos',
    assistantTitle: 'Assistant BCM',
    assistantIntro: 'Une auto-évaluation guidée sur les 10 piliers de résilience. Répondez avec vos mots ou posez une question à tout moment.',
    pillarProgress: 'Pilier {n} sur {total}',
    answerHint: 'Décrivez votre pratique actuelle — ou posez une question…',
    send: 'Envoyer',
    maturityLabel: 'Maturité',
    nextPillar: 'Pilier suivant',
    skip: 'Passer',
    assessing: 'Évaluation…',
    assessmentComplete: 'Évaluation terminée',
    overallReadiness: 'Préparation globale',
    scannerTitle: 'Scanner d’incidents',
    scannerIntro: 'Collez ou décrivez un incident opérationnel. Gemma le classe sur l’appareil et évalue la résilience.',
    incidentHint: 'Collez ou décrivez l’incident…',
    analyze: 'Analyser',
    analyzing: 'Analyse…',
    category: 'Catégorie',
    severity: 'Gravité',
    impactArea: 'Zone d’impact',
    resilienceScore: 'Score de résilience',
    likelihood: 'Probabilité',
    controlMaturity: 'Maturité du contrôle',
    low: 'Faible',
    medium: 'Moyenne',
    high: 'Élevée',
    aboutTitle: 'À propos et confidentialité',
    privacyNote: 'Tout le traitement se fait sur cet appareil. Vos saisies, discussions et registres ne quittent jamais votre téléphone.',
    disclaimerTitle: 'Avertissement de conformité',
    tabTools: 'Outils',
    toolsIntro: 'Configurez les tolérances d’impact et cartographiez les dépendances de énième partie. Ces données alimentent les piliers Tolérance et Tiers de l’Assistant.',
    impactToleranceTitle: 'Configurateur de tolérance d’impact',
    nthPartyTitle: 'Cartographe des dépendances de énième partie',
    serviceName: 'Service critique',
    vendorName: 'Fournisseur',
    serviceProvided: 'Service fourni',
    nthPartiesLabel: 'Dépendances de énième partie (séparées par des virgules)',
    add: 'Ajouter',
    concentrationRisk: 'Risque de concentration',
    sharedByVendors: 'partagée par {n} fournisseurs',
    noConcentrationRisk: 'Aucune dépendance de énième partie partagée détectée.',
    emptyTolerance: 'Aucun service critique configuré pour l’instant.',
    emptyVendors: 'Aucun fournisseur cartographié pour l’instant.',
  ),
  'pt': AppStrings(
    appTitle: 'Resilience Compass',
    appSubtitle: 'Resiliência operacional no dispositivo',
    offlineBadge: 'Offline · No dispositivo',
    setupWelcome: 'Configure sua avaliação',
    chooseLanguage: 'Idioma',
    chooseJurisdictions: 'Jurisdições regulatórias',
    jurisdictionHint: 'Selecione todas as aplicáveis. A ISO 22301 é sempre incluída como base.',
    isoAlwaysOn: 'Base · sempre ativa',
    loadModel: 'Carregar modelo no dispositivo',
    loadingModel: 'Carregando modelo…',
    modelReady: 'Modelo pronto — funciona totalmente offline',
    start: 'Começar',
    continueLabel: 'Continuar',
    retry: 'Tentar novamente',
    modelLoadError: 'Não foi possível carregar o modelo. Verifique o arquivo do modelo e tente novamente.',
    tabAssistant: 'Assistente',
    tabScanner: 'Scanner',
    menuAbout: 'Sobre',
    assistantTitle: 'Assistente BCM',
    assistantIntro: 'Uma autoavaliação guiada pelos 10 pilares de resiliência. Responda com suas palavras ou faça uma pergunta a qualquer momento.',
    pillarProgress: 'Pilar {n} de {total}',
    answerHint: 'Descreva sua prática atual — ou faça uma pergunta…',
    send: 'Enviar',
    maturityLabel: 'Maturidade',
    nextPillar: 'Próximo pilar',
    skip: 'Pular',
    assessing: 'Avaliando…',
    assessmentComplete: 'Avaliação concluída',
    overallReadiness: 'Prontidão geral',
    scannerTitle: 'Scanner de incidentes',
    scannerIntro: 'Cole ou descreva um incidente operacional. O Gemma o classifica no dispositivo e pontua a resiliência.',
    incidentHint: 'Cole ou descreva o incidente…',
    analyze: 'Analisar',
    analyzing: 'Analisando…',
    category: 'Categoria',
    severity: 'Severidade',
    impactArea: 'Área de impacto',
    resilienceScore: 'Pontuação de resiliência',
    likelihood: 'Probabilidade',
    controlMaturity: 'Maturidade do controle',
    low: 'Baixa',
    medium: 'Média',
    high: 'Alta',
    aboutTitle: 'Sobre e privacidade',
    privacyNote: 'Todo o processamento acontece neste dispositivo. Suas entradas, conversas e registros nunca saem do seu telefone.',
    disclaimerTitle: 'Aviso de conformidade',
    tabTools: 'Ferramentas',
    toolsIntro: 'Configure as tolerâncias de impacto e mapeie as dependências de enésima parte. Esses dados fundamentam os pilares de Tolerância e Terceiros do Assistente.',
    impactToleranceTitle: 'Configurador de tolerância de impacto',
    nthPartyTitle: 'Mapeador de dependências de enésima parte',
    serviceName: 'Serviço crítico',
    vendorName: 'Fornecedor',
    serviceProvided: 'Serviço prestado',
    nthPartiesLabel: 'Dependências de enésima parte (separadas por vírgulas)',
    add: 'Adicionar',
    concentrationRisk: 'Risco de concentração',
    sharedByVendors: 'compartilhada por {n} fornecedores',
    noConcentrationRisk: 'Nenhuma dependência de enésima parte compartilhada detectada.',
    emptyTolerance: 'Nenhum serviço crítico configurado ainda.',
    emptyVendors: 'Nenhum fornecedor mapeado ainda.',
  ),
};

/// Look up strings for a language code, falling back to English.
AppStrings stringsFor(String code) => kStrings[code] ?? kStrings['en']!;
