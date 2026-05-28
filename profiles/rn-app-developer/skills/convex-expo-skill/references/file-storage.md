# File uploads and storage

## Table of contents

- [Upload URLs (3-step flow)](#upload-urls-3-step-flow)
- [Server mutations](#server-mutations)
- [Expo client example](#expo-client-example)
- [HTTP actions (webhooks, custom upload endpoints)](#http-actions-webhooks-custom-upload-endpoints)
- [Serving stored files](#serving-stored-files)
- [Modeling file metadata](#modeling-file-metadata)

Convex file storage is backed by a system table named `"_storage"`.

There are two main approaches:

1) Upload URLs (recommended for large files)
2) HTTP actions (single request, more control, size limits)

## Upload URLs (3-step flow)

Client makes 3 requests:

1. Call a mutation to generate an upload URL (`ctx.storage.generateUploadUrl()`)
2. POST the file bytes to that URL and receive a `storageId`
3. Call another mutation to save the `storageId` in your app data

### Server mutations

Generate the upload URL:

```ts
// convex/files.ts
import { mutation } from "./_generated/server";

export const generateUploadUrl = mutation({
  args: {},
  handler: async (ctx) => {
    // Add auth checks here if you only want signed-in users to upload.
    return await ctx.storage.generateUploadUrl();
  },
});
```

Persist the new storageId:

```ts
import { mutation } from "./_generated/server";
import { v } from "convex/values";

export const saveImage = mutation({
  args: {
    storageId: v.id("_storage"),
    taskId: v.id("tasks"),
  },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.taskId, { imageId: args.storageId });
  },
});
```

### Expo client example

This is an outline you can adapt.

```ts
import * as ImagePicker from "expo-image-picker";
import { useMutation } from "convex/react";
import { api } from "../convex/_generated/api";

export function useUploadTaskImage() {
  const generateUploadUrl = useMutation(api.files.generateUploadUrl);
  const saveImage = useMutation(api.files.saveImage);

  return async function upload(taskId: string) {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      quality: 0.9,
    });
    if (result.canceled) return;

    const asset = result.assets[0];
    const blob = await (await fetch(asset.uri)).blob();

    const postUrl = await generateUploadUrl();
    const uploadRes = await fetch(postUrl, {
      method: "POST",
      headers: {
        "Content-Type": blob.type || "application/octet-stream",
      },
      body: blob,
    });
    const { storageId } = await uploadRes.json();

    await saveImage({ taskId, storageId });
  };
}
```

## HTTP actions (webhooks, custom upload endpoints)

HTTP actions:
- take a Fetch `Request`
- return a Fetch `Response`
- can call queries/mutations/actions
- are useful for webhooks or when you need to control the upload flow more tightly

Notes:
- HTTP actions live behind the `.convex.site` URL.
- CORS matters if calling from browsers.
- Request/response size is limited (commonly 20MB).

## Serving stored files

You typically:
- store `storageId` in a table
- later request a signed URL via `ctx.storage.getUrl(storageId)` from a query
- load the signed URL in the client

## Modeling file metadata

Do not store huge blobs in your main documents. Instead store:
- `storageId: Id<"_storage">`
- file type, size, original filename (optional)
- ownership fields like `userId`
