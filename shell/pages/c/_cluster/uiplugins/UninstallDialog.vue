<script>
import AsyncButton from '@shell/components/AsyncButton';
import { CATALOG } from '@shell/config/types';

import { UI_PLUGIN_NAMESPACE } from '@shell/config/uiplugins';

export default {
  components: { AsyncButton },

  data() {
    return { plugin: undefined, busy: false };
  },

  methods: {
    showDialog(plugin) {
      this.plugin = plugin;
      this.busy = false;
      this.$modal.show('uninstallPluginDialog');
    },
    closeDialog(result) {
      this.$modal.hide('uninstallPluginDialog');
      this.$emit('closed', result);
    },
    async uninstall() {
      this.busy = true;

      const plugin = this.plugin;

      this.$emit('update', plugin.name, 'uninstall');

      // Delete the CR if this is a developer plugin (there is no Helm App, so need to remove the CRD ourselves)
      if (plugin.uiplugin?.isDeveloper) {
        // Delete the custom resource
        await plugin.uiplugin.remove();
      }

      // Find the app for this plugin
      const apps = await this.$store.dispatch('management/findAll', { type: CATALOG.APP });

      const pluginApp = apps.find((app) => {
        return app.namespace === UI_PLUGIN_NAMESPACE && app.name === plugin.name;
      });

      if (pluginApp) {
        try {
          await pluginApp.remove();
        } catch (e) {
          this.$store.dispatch('growl/error', {
            title:   this.t('plugins.error.generic'),
            message: e.message ? e.message : e,
            timeout: 10000
          }, { root: true });
        }

        await this.$store.dispatch('management/findAll', { type: CATALOG.OPERATION });
      }

      this.closeDialog(plugin);
    }
  }
};
</script>

<template>
  <modal
    name="uninstallPluginDialog"
    height="auto"
    :scrollable="true"
  >
    <div
      v-if="plugin"
      class="plugin-install-dialog"
    >
      <h4 class="mt-10">
        {{ t('plugins.uninstall.title', { name: plugin.label }) }}
      </h4>
      <div class="mt-10 dialog-panel">
        <div class="dialog-info">
          <p>
            {{ t('plugins.uninstall.prompt') }}
          </p>
        </div>
        <div class="dialog-buttons">
          <button
            :disabled="busy"
            class="btn role-secondary"
            data-testid="uninstall-ext-modal-cancel-btn"
            @click="closeDialog(false)"
          >
            {{ t('generic.cancel') }}
          </button>
          <AsyncButton
            mode="uninstall"
            data-testid="uninstall-ext-modal-uninstall-btn"
            @click="uninstall()"
          />
        </div>
      </div>
    </div>
  </modal>
</template>

<style lang="scss" scoped>
  .plugin-install-dialog {
    padding: 10px;

    h4 {
      font-weight: bold;
    }

    .dialog-panel {
      display: flex;
      flex-direction: column;
      min-height: 100px;

      .dialog-info {
        flex: 1;
      }
    }

    .dialog-buttons {
      display: flex;
      justify-content: flex-end;
      margin-top: 10px;

      > *:not(:last-child) {
        margin-right: 10px;
      }
    }
  }
</style>
