<script lang="ts">
  import type { YancySchema, YancyListQuery } from "./types";
  import { marked } from "marked";
  import DatabaseTable from "./database-table.svelte";
  import { tick } from "svelte";
  import { Dialog, Portal } from "@skeletonlabs/skeleton-svelte";
  import ItemForm from "./item-form.svelte";

  let {
    src,
    schema,
    query,
    onchange,
  }: {
    src: string;
    schema: string;
    query: YancyListQuery;
    onchange?: (schema: string, item: { [key: string]: any }) => void;
  } = $props();

  const apiUrl = src + "/api";
  const websiteUrl = src + "/website";

  class DataSchema {
    schema: YancySchema | undefined = $state();
    error = $state();
    isLoading = $state(false);

    get idFields() {
      if (!this.schema || !this.schema["x-id-field"]) {
        return [];
      }
      return Array.isArray(this.schema["x-id-field"])
        ? this.schema["x-id-field"]
        : [this.schema["x-id-field"]];
    }
  }

  function fetchSchema(schema: string): DataSchema {
    const resp = new DataSchema();

    async function fetchSchema() {
      resp.isLoading = true;
      try {
        const response = await fetch(apiUrl);
        const allSchema = await response.json();
        if (allSchema[schema]) {
          resp.schema = allSchema[schema];
          resp.error = undefined;
        } else {
          resp.error = new Error("Schema not found");
        }
      } catch (err) {
        resp.error = err;
        resp.schema = undefined;
      }
      resp.isLoading = false;
    }

    fetchSchema();
    return resp;
  }

  let dataSchema = $derived(fetchSchema(schema));

  // The row we are currently editing, unchanged
  let editRow: any = $state();

  function addRow() {
    openFormForRow({});
  }

  async function openFormForRow(row: any) {
    const dialog = document.getElementById("edit-dialog") as
      | HTMLDialogElement
      | undefined;
    if (dialog) {
      dialog.showModal();
    }
    editRow = row;

    // Wait for the form to render
    await tick();

    // Focus the user on the first editable field in the form
    // XXX: Using the autofocus attribute would probably be better here, but
    // that would be in the edit-form and we might have times we don't want to
    // autofocus.
    const form = document.querySelector("#edit-form");
    if (!form) {
      console.warn("Could not find #edit-form to focus");
      return;
    }
    for (const el of form.querySelectorAll(
      "input,textarea,select,[contenteditable]",
    ) as NodeListOf<HTMLElement>) {
      if (!el.hasAttribute("disabled")) {
        el.focus();
        break;
      }
    }
  }

  let dataTable: DatabaseTable | undefined = $state();

  /**
   * Close the dialog, no matter what has been done.
   */
  function closeDialog() {
    // This is the not-gentle "close"
    console.log("closeDialog");
    editRow = undefined;
  }

  /**
   * Cancel editing whatever is in the dialog. Show a pop-up if whatever has
   * been edited and user would lose changes.
   */
  function cancelDialog() {
    // This is the gentle "request close"
    console.log("cancelDialog");
    // XXX: Warn user before doing this
    closeDialog();
  }

  function onsave(item: any) {
    // Refresh page
    if (dataTable) {
      dataTable.refresh();
    }
    onchange?.(schema, item);
    closeDialog();
  }

  /**
   * Fill in {field} placeholders. Used for building URLs.
   */
  function fillPlaceholder(
    template: string,
    fields: { [key: string]: any },
  ): string {
    return template.replaceAll(/{\s*([^}\s]+)\s*}/g, (_, key) => fields[key]);
  }
</script>

{#if dataSchema.isLoading}
  Fetching...
{:else}
  <div class="database-editor" role="region" aria-label="Database Editor">
    {#if !dataSchema.schema}
      Schema not found
    {:else}
      <h2 id="table-name">
        {dataSchema.schema.title ? dataSchema.schema.title : schema}
      </h2>
      {#if dataSchema.schema["x-view-item-url"]}
        <a
          class="chip preset-outlined-secondary-500"
          href={websiteUrl + dataSchema.schema["x-view-url"]}>View</a
        >
      {/if}
      {#if dataSchema.schema.description}
        <div>{marked(dataSchema.schema.description)}</div>
      {/if}

      <button onclick={() => addRow()} class="btn preset-outlined-primary-500"
        >Add</button
      >

      <DatabaseTable
        bind:this={dataTable}
        aria-labelledby="table-name"
        schema={dataSchema.schema}
        src={apiUrl + "/" + schema}
        {query}
      >
        {#snippet controls(row: any)}
          <button
            onclick={() => openFormForRow(row)}
            class="chip preset-outlined-primary-500">Edit</button
          >
          {#if dataSchema.schema["x-view-item-url"]}
            <a
              class="chip preset-outlined-secondary-500"
              href={websiteUrl +
                fillPlaceholder(dataSchema.schema["x-view-item-url"], row)}
              >View</a
            >
          {/if}
        {/snippet}
      </DatabaseTable>

      <Dialog
        open={editRow}
        onRequestDismiss={cancelDialog}
        onEscapeKeyDown={cancelDialog}
        onInteractOutside={cancelDialog}
        onPointerDownOutside={cancelDialog}
        onFocusOutside={cancelDialog}
        class="dialog preset-filled-surface-100-900 animate-dialog"
      >
        <Portal>
          <Dialog.Backdrop class="fixed inset-0 bg-surface-100-900/75" />
          <Dialog.Positioner
            class="fixed inset-0 flex justify-center items-center"
          >
            <Dialog.Content
              class="card w-contents min-w-2xl h-screen max-h-screen overflow-y-auto bg-surface-100-900 p-4 space-y-2 shadow-xl flex flex-col"
            >
              <header>
                <Dialog.Title id="edit-item-heading" class="text-2xl font-bold"
                  >Edit Item</Dialog.Title
                >
              </header>
              <ItemForm
                {src}
                {schema}
                item={editRow}
                oncancel={cancelDialog}
                {onsave}
              />
            </Dialog.Content>
          </Dialog.Positioner>
        </Portal>
      </Dialog>
    {/if}
  </div>
{/if}

<style>
  .database-editor {
    padding: var(--pico-spacing);
  }
</style>
