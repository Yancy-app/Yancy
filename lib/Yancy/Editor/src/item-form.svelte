<script lang="ts">
  import type { YancySchema } from "./types";
  import ObjectField from "./object-field.svelte";
  import type { HTMLFormAttributes } from "svelte/elements";

  let {
    src,
    schema,
    item = {},
    oncancel,
    onsave,
    ...attrs
  }: {
    src: string;
    schema: string;
    item: any;
    onsave?: (item: { [key: string]: any }) => void;
    oncancel?: () => void;
    attrs: HTMLFormAttributes;
  } = $props();

  const apiUrl = src + "/api";
  const storageUrl = src + "/storage";

  // The row we are currently editing, with changes
  let changedRow: any = $derived(JSON.parse(JSON.stringify(item)));

  // Errors by field
  let fieldErrors: any = $state({});
  // Errors not attached to any field
  let objectErrors: any = $state([]);

  let hasError = $derived(
    Object.keys(fieldErrors).length > 0 || objectErrors.length > 0,
  );

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

  async function saveRow(e: SubmitEvent) {
    e.preventDefault();

    const row = JSON.parse(JSON.stringify(changedRow));
    fieldErrors = {};
    objectErrors = [];

    let url = apiUrl + "/" + schema;
    // If some ID fields are not read-only, we need to use the old value in the
    // URL, and the new value in the form body.
    if (dataSchema.idFields.every((k) => item[k])) {
      url += "/" + dataSchema.idFields.map((k) => item[k]).join("/");
    }

    // Remove all read-only fields, since we can't set them
    for (const [key, schema] of Object.entries(
      dataSchema.schema?.properties || {},
    )) {
      if (typeof schema === "object" && schema?.readOnly) {
        delete row[key];
      }
    }

    const res = await fetch(url, {
      method: "POST",
      body: JSON.stringify(row),
    });
    if (!res.ok) {
      // Build the error structure so we can show errors next to the fields
      const error = await res.json();
      console.error(error);
      if (error.errors && Array.isArray(error.errors)) {
        for (const err of error.errors) {
          if (!err.path || typeof err.path !== "string" || err.path === "/") {
            // Not a field error, so add it to the generic pile
            objectErrors.push(err.message);
            continue;
          }
          if (typeof err.path === "string") {
            const pathParts = err.path.split("/").slice(1);
            let fieldErr = fieldErrors;
            for (const part of pathParts) {
              fieldErr[part] ??= {};
              fieldErr = fieldErr[part];
            }
            fieldErr.$errors ??= [];
            fieldErr.$errors.push(err);
          }
        }
      }
      return;
    }

    if (onsave) {
      // FIXME: 201 Created responses should give us the whole set of ID fields as some kind of JSON
      onsave(changedRow);
    }
  }

  function cancel() {
    if (oncancel) {
      oncancel();
    }
  }
</script>

<form onsubmit={saveRow} {...attrs}>
  {#if hasError}
    <div role="alert" aria-describedby="error-description">
      <span id="error-description">Error</span>
      {#if objectErrors.length > 0}
        <ul>
          {#each objectErrors as error}
            <li>{error}</li>
          {/each}
        </ul>
      {/if}
    </div>
  {/if}
  <ObjectField
    storage={storageUrl}
    schema={dataSchema.schema}
    value={changedRow}
    errors={fieldErrors}
    onchange={(newValue) => {
      changedRow = newValue;
    }}
  />
  <button class="btn preset-filled-primary-500">Save</button>
  <button
    type="button"
    onclick={cancel}
    class="btn preset-outlined-secondary-500">Cancel</button
  >
</form>
