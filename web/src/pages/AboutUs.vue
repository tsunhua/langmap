<template>
  <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <div class="bg-white rounded-lg shadow-md p-6 md:p-8">
      <h1 class="text-3xl font-bold text-gray-900 mb-6 text-center">关于 LangMap</h1>
      
      <div class="prose prose-lg max-w-none">
        <section class="mb-10">
          <h2 class="text-2xl font-semibold text-gray-800 mb-4 flex items-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 mr-2 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
            </svg>
            项目目的
          </h2>
          <p class="text-gray-600 mb-4">
            LangMap 是一个开源、社区驱动的在线语言地图项目，致力于收集世界各地的语言短语和表达方式，展示不同语言之间的差异，并为语言爱好者提供有价值的资源。我们的目标是建立一个全球语言表达的共享平台，让每个人都能轻松学习和探索各种语言的独特之处。
          </p>
          <p class="text-gray-600 mb-4">
            通过 LangMap，我们希望：
          </p>
          <ul class="list-disc list-inside text-gray-600 space-y-2">
            <li>保护和传承濒危语言和方言</li>
            <li>展示同一概念在不同语言中的多样表达</li>
            <li>促进跨文化交流和理解</li>
            <li>为语言研究者和爱好者提供实用工具</li>
          </ul>
        </section>

        <section class="mb-10">
          <h2 class="text-2xl font-semibold text-gray-800 mb-4 flex items-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 mr-2 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4" />
            </svg>
            基本使用操作
          </h2>
          
          <h3 class="text-xl font-medium text-gray-700 mb-2">浏览表达内容</h3>
          <ol class="list-decimal list-inside text-gray-600 space-y-2 mb-6">
            <li>访问主页浏览最新添加的语言表达</li>
            <li>使用搜索功能查找特定词语或短语</li>
            <li>点击表达卡片查看详细信息和历史版本</li>
          </ol>
          
          <h3 class="text-xl font-medium text-gray-700 mb-2">添加新表达（需要注册账户）</h3>
          <ol class="list-decimal list-inside text-gray-600 space-y-2 mb-6">
            <li>点击右上角的"登录"按钮进行注册或登录</li>
            <li>登录后，在主页点击"添加新表达"按钮</li>
            <li>填写表达的基本信息，包括：
              <ul class="list-disc list-inside ml-6 mt-2 space-y-1">
                <li>选择语言</li>
                <li>输入词语或短语</li>
                <li>提供定义和用法说明</li>
                <li>添加例句</li>
              </ul>
            </li>
            <li>提交审核，等待管理员确认</li>
          </ol>
          
          <h3 class="text-xl font-medium text-gray-700 mb-2">切换语言界面</h3>
          <ol class="list-decimal list-inside text-gray-600 space-y-2">
            <li>在页面右上角找到语言切换下拉菜单</li>
            <li>选择您偏好的界面语言</li>
            <li>系统会自动保存您的语言偏好设置</li>
          </ol>
        </section>

        <section>
          <h2 class="text-2xl font-semibold text-gray-800 mb-4 flex items-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 mr-2 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
            </svg>
            版权声明
          </h2>
          
          <h3 class="text-xl font-medium text-gray-700 mb-2">用户提交内容版权</h3>
          <p class="text-gray-600 mb-4">
            当您向 LangMap 提交内容时，您同意以下条款：
          </p>
          <ol class="list-decimal list-inside text-gray-600 space-y-2 mb-4">
            <li><strong>原创性保证</strong>：您保证所提交的内容为您原创，或者您拥有合法的使用权。</li>
            <li><strong>授权许可</strong>：您授予 LangMap 全球范围内的免版税、非独占性、不可撤销的许可，允许我们：
              <ul class="list-disc list-inside ml-6 mt-2 space-y-1">
                <li>使用、复制、修改您提交的内容</li>
                <li>将内容分发、传播、公开展示和表演</li>
                <li>创建基于您提交内容的衍生作品</li>
              </ul>
            </li>
            <li><strong>责任声明</strong>：您对提交内容的合法性、准确性、完整性承担全部责任。LangMap 不对用户提交的内容承担责任。</li>
            <li><strong>隐私权</strong>：您承诺提交的内容不会侵犯任何第三方的隐私权或其他合法权益。</li>
          </ol>
          
          <h3 class="text-xl font-medium text-gray-700 mb-2">平台内容使用</h3>
          <p class="text-gray-600 mb-4">
            LangMap 上的所有内容均遵循以下原则：
          </p>
          <ul class="list-disc list-inside text-gray-600 space-y-2 mb-4">
            <li><strong>教育用途优先</strong>：我们鼓励将平台上的内容用于教育和学术研究目的。</li>
            <li><strong>合理引用</strong>：如果您在其他地方使用 LangMap 的内容，请确保适当引用来源。</li>
            <li><strong>禁止商业滥用</strong>：未经明确许可，不得将平台内容用于商业盈利目的。</li>
            <li><strong>开放知识精神</strong>：我们支持知识共享的理念，但尊重所有贡献者的知识产权。</li>
          </ul>
          
          <h3 class="text-xl font-medium text-gray-700 mb-2">技术和代码版权</h3>
          <p class="text-gray-600 mb-4">
            LangMap 的源代码采用 MIT 许可证发布，这意味着您可以自由地使用、复制、修改和分发代码，但需保留原始版权声明。
          </p>
        </section>
      </div>
      
      <div class="mt-10 pt-6 border-t border-gray-200 text-center">
        <p class="text-gray-600">
          感谢您成为 LangMap 社区的一员！让我们一起为世界语言文化的多样性做出贡献。
        </p>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'AboutUs'
}
</script>

<style scoped>
.prose :where(h2):not(:where([class~="not-prose"] *)) {
  margin-top: 1em;
}

.prose :where(ul > li):not(:where([class~="not-prose"] *)) {
  margin-top: 0.5em;
  margin-bottom: 0.5em;
}
</style>