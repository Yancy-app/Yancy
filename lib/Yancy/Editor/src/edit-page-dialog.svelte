<script lang="ts">
  import XIcon from "@lucide/svelte/icons/x";
  import { Dialog, Portal } from "@skeletonlabs/skeleton-svelte";
  import type { Page } from "./types";
  import ItemForm from "./item-form.svelte";

  let {
    src,
    open,
    page,
    oncancel,
    onsave,
  }: {
    src: string;
    open: boolean;
    page?: Page;
    onsave: (page: Page) => void;
    oncancel: () => void;
  } = $props();

  async function save(newItem: { [key: string]: any }) {
    onsave(newItem as Page);
  }
</script>

<Dialog {open}>
  <Portal>
    <Dialog.Backdrop class="fixed inset-0 z-50 bg-surface-50-950/50" />
    <Dialog.Positioner
      class="fixed inset-0 z-50 flex justify-center items-center p-4"
    >
      <Dialog.Content
        class="card bg-surface-100-900 w-full max-w-xl p-4 space-y-4 shadow-xl"
      >
        <header class="flex justify-between items-center">
          <Dialog.Title id="edit-page-heading" class="text-lg font-bold"
            >Edit Page</Dialog.Title
          >
          <Dialog.CloseTrigger class="btn-icon hover:preset-tonal">
            <XIcon class="size-4" />
          </Dialog.CloseTrigger>
        </header>

        <ItemForm
          aria-labelledby="edit-page-heading"
          item={page}
          schema="pages"
          {src}
          onsave={save}
          {oncancel}
        />
      </Dialog.Content>
    </Dialog.Positioner>
  </Portal>
</Dialog>
