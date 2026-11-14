<script lang="ts">
  import { onMount } from "svelte";
  import { useListCollection, Listbox } from "@skeletonlabs/skeleton-svelte";

  let {
    src,
  }: {
    src: string;
  } = $props();

  let files = $state([]);
  const collection = $derived(
    useListCollection({
      items: files,
      itemToString: (item) => item,
      itemToValue: (item) => item,
    }),
  );

  onMount(async () => {
    const res = await fetch(src);
    if (res.ok) {
      const data = await res.json();
      files = data.items;
    }
  });
</script>

<div>
  <Listbox class="w-full max-w-md" {collection}>
    <Listbox.Content>
      {#each collection.items as item}
        <Listbox.Item {item}>
          <Listbox.ItemText>{item}</Listbox.ItemText>
          <Listbox.ItemIndicator />
        </Listbox.Item>
      {/each}
    </Listbox.Content>
  </Listbox>
</div>

<style>
</style>
