<template>
  <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <div class="bg-white rounded-lg shadow-md p-6 md:p-8">
      <h1 class="text-3xl font-bold text-gray-900 mb-6 text-center">About LangMap</h1>
      
      <div class="prose prose-lg max-w-none">
        <section class="mb-10">
          <h2 class="text-2xl font-semibold text-gray-800 mb-4 flex items-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 mr-2 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
            </svg>
            Project Purpose
          </h2>
          <p class="text-gray-600 mb-4">
            LangMap is an open-source, community-driven online language map project dedicated to collecting linguistic phrases and expressions from around the world, showcasing differences between languages, and providing valuable resources for language enthusiasts. Our goal is to build a shared platform for global language expressions, allowing everyone to easily learn and explore the uniqueness of various languages.
          </p>
          <p class="text-gray-600 mb-4">
            Through LangMap, we hope to:
          </p>
          <ul class="list-disc list-inside text-gray-600 space-y-2">
            <li>Preserve and pass on endangered languages and dialects</li>
            <li>Showcase diverse expressions of the same concept in different languages</li>
            <li>Promote cross-cultural communication and understanding</li>
            <li>Provide practical tools for linguists and language enthusiasts</li>
          </ul>
        </section>

        <section class="mb-10">
          <h2 class="text-2xl font-semibold text-gray-800 mb-4 flex items-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 mr-2 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4" />
            </svg>
            Basic Usage
          </h2>
          
          <h3 class="text-xl font-medium text-gray-700 mb-2">Browsing Expressions</h3>
          <ol class="list-decimal list-inside text-gray-600 space-y-2 mb-6">
            <li>Visit the homepage to browse recently added linguistic expressions</li>
            <li>Use the search function to find specific words or phrases</li>
            <li>Click on expression cards to view detailed information and historical versions</li>
          </ol>
          
          <h3 class="text-xl font-medium text-gray-700 mb-2">Adding New Expressions (Requires Account)</h3>
          <ol class="list-decimal list-inside text-gray-600 space-y-2 mb-6">
            <li>Click the "Login" button in the top right corner to register or log in</li>
            <li>After logging in, click the "Add New Expression" button on the homepage</li>
            <li>Fill in the basic information of the expression, including:
              <ul class="list-disc list-inside ml-6 mt-2 space-y-1">
                <li>Select language</li>
                <li>Enter word or phrase</li>
                <li>Provide definition and usage instructions</li>
                <li>Add example sentences</li>
              </ul>
            </li>
            <li>Submit for review and wait for administrator confirmation</li>
          </ol>
          
          <h3 class="text-xl font-medium text-gray-700 mb-2">Switching Interface Language</h3>
          <ol class="list-decimal list-inside text-gray-600 space-y-2">
            <li>Find the language switch dropdown menu in the upper right corner of the page</li>
            <li>Select your preferred interface language</li>
            <li>The system will automatically save your language preference settings</li>
          </ol>
        </section>

        <section>
          <h2 class="text-2xl font-semibold text-gray-800 mb-4 flex items-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 mr-2 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
            </svg>
            Service Policies
          </h2>
          
          <p class="text-gray-600 mb-4">
            For information about our Terms of Service, Privacy Policy, and Content Policy, please visit our dedicated 
            <router-link to="/policies" class="text-blue-600 hover:text-blue-800 underline">Policies page</router-link>.
          </p>
          <p class="text-gray-600 mb-4">
            Contact: langmapio.gmail.com
          </p>
        </section>
      </div>
      
      <div class="mt-10 pt-6 border-t border-gray-200 text-center">
        <p class="text-gray-600">
          Thank you for becoming a member of the LangMap community! Let's contribute to the diversity of world language culture together.
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