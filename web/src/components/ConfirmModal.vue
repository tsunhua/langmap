<template>
  <div v-if="modelValue" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
    <div class="bg-white rounded-lg shadow-xl max-w-md w-full p-6">
      <h2 :class="['text-xl font-bold mb-4', danger ? 'text-red-600' : 'text-gray-900']">
        {{ title || $t('confirm_action') || '再次確認' }}
      </h2>
      
      <p class="mb-6 text-gray-700 whitespace-pre-line">
        {{ message }}
      </p>

      <div class="flex justify-end gap-3">
        <button type="button" @click="handleCancel"
          class="px-4 py-2 border border-gray-300 rounded text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          :disabled="loading">
          {{ cancelText || $t('cancel') || 'Cancel' }}
        </button>
        <button type="button" @click="handleConfirm" 
          :class="[
            'px-4 py-2 text-white rounded disabled:opacity-50 disabled:cursor-not-allowed',
            danger ? 'bg-red-600 hover:bg-red-700' : 'bg-blue-600 hover:bg-blue-700'
          ]"
          :disabled="loading">
          {{ loading ? (loadingText || $t('processing') || 'Processing...') : (confirmText || $t('confirm') || 'Confirm') }}
        </button>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ConfirmModal',
  props: {
    modelValue: {
      type: Boolean,
      required: true
    },
    title: {
      type: String,
      default: ''
    },
    message: {
      type: String,
      required: true
    },
    confirmText: {
      type: String,
      default: ''
    },
    cancelText: {
      type: String,
      default: ''
    },
    loadingText: {
      type: String,
      default: ''
    },
    danger: {
      type: Boolean,
      default: true
    },
    loading: {
      type: Boolean,
      default: false
    }
  },
  emits: ['update:modelValue', 'confirm', 'cancel'],
  setup(props, { emit }) {
    const handleCancel = () => {
      if (props.loading) return;
      emit('update:modelValue', false);
      emit('cancel');
    };

    const handleConfirm = () => {
      if (props.loading) return;
      emit('confirm');
    };

    return {
      handleCancel,
      handleConfirm
    };
  }
}
</script>
