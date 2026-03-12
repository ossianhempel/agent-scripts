    # RevenueCat API v2 reference

    This note summarizes the RevenueCat API v2 surface included in the bundled OpenAPI document.

    ## Core rules

    - Base URL: `https://api.revenuecat.com/v2`
    - Auth: `Authorization: Bearer <API_V2_SECRET_KEY>`
    - Writes use JSON request bodies with `Content-Type: application/json`
    - Top-level list endpoints support `limit` and `starting_after`
    - List responses return `object`, `items`, `url`, and optional `next_page`
    - Use `expand=` when you need expandable related objects in the same response
    - API v2 is still evolving, so not every old v1 capability is present yet

    ## Rate limits called out in the docs

    - Customer Information: 480 requests/minute
    - Charts & Metrics: 5 requests/minute
    - Project Configuration: 60 requests/minute
    - Virtual Currencies create transaction: 480 requests/minute

    ## Operations by area

    ## Project

| Method | Path | Operation | Permission scope |
|---|---|---|---|
| `GET` | `/projects` | `list-projects` | `project_configuration:projects:read` |
| `POST` | `/projects` | `create-project` | `project_configuration:projects:read_write` |

## App

| Method | Path | Operation | Permission scope |
|---|---|---|---|
| `GET` | `/projects/{project_id}/apps/{app_id}/public_api_keys` | `list-app-public-api-keys` | `project_configuration:apps:read` |
| `GET` | `/projects/{project_id}/apps` | `list-apps` | `project_configuration:apps:read` |
| `POST` | `/projects/{project_id}/apps` | `create-app` | `project_configuration:apps:read_write` |
| `GET` | `/projects/{project_id}/apps/{app_id}` | `get-app` | `project_configuration:apps:read` |
| `POST` | `/projects/{project_id}/apps/{app_id}` | `update-app` | `project_configuration:apps:read_write` |
| `DELETE` | `/projects/{project_id}/apps/{app_id}` | `delete-app` | `project_configuration:apps:read_write` |
| `GET` | `/projects/{project_id}/apps/{app_id}/store_kit_config` | `get-app-storekit-config` | `project_configuration:apps:read` |

## Product

| Method | Path | Operation | Permission scope |
|---|---|---|---|
| `GET` | `/projects/{project_id}/products/{product_id}` | `get-product` | `project_configuration:products:read` |
| `DELETE` | `/projects/{project_id}/products/{product_id}` | `delete-product` | `project_configuration:products:read_write` |
| `POST` | `/projects/{project_id}/products/{product_id}/create_in_store` | `create-product-in-store` | `project_configuration:products:read_write` |
| `GET` | `/projects/{project_id}/products` | `list-products` | `project_configuration:products:read` |
| `POST` | `/projects/{project_id}/products` | `create-product` | `project_configuration:products:read_write` |

## Entitlement

| Method | Path | Operation | Permission scope |
|---|---|---|---|
| `GET` | `/projects/{project_id}/entitlements/{entitlement_id}` | `get-entitlement` | `project_configuration:entitlements:read` |
| `POST` | `/projects/{project_id}/entitlements/{entitlement_id}` | `update-entitlement` | `project_configuration:entitlements:read_write` |
| `DELETE` | `/projects/{project_id}/entitlements/{entitlement_id}` | `delete-entitlement` | `project_configuration:entitlements:read_write` |
| `GET` | `/projects/{project_id}/entitlements` | `list-entitlements` | `project_configuration:entitlements:read` |
| `POST` | `/projects/{project_id}/entitlements` | `create-entitlement` | `project_configuration:entitlements:read_write` |
| `GET` | `/projects/{project_id}/entitlements/{entitlement_id}/products` | `get-products-from-entitlement` | `project_configuration:entitlements:read` |
| `POST` | `/projects/{project_id}/entitlements/{entitlement_id}/actions/attach_products` | `attach-products-to-entitlement` | `project_configuration:entitlements:read_write` |
| `POST` | `/projects/{project_id}/entitlements/{entitlement_id}/actions/detach_products` | `detach-products-from-entitlement` | `project_configuration:entitlements:read_write` |

## Offering

| Method | Path | Operation | Permission scope |
|---|---|---|---|
| `GET` | `/projects/{project_id}/offerings/{offering_id}` | `get-offering` | `project_configuration:offerings:read` |
| `POST` | `/projects/{project_id}/offerings/{offering_id}` | `update-offering` | `project_configuration:offerings:read_write` |
| `DELETE` | `/projects/{project_id}/offerings/{offering_id}` | `delete-offering` | `project_configuration:offerings:read_write` |
| `GET` | `/projects/{project_id}/offerings` | `list-offerings` | `project_configuration:offerings:read` |
| `POST` | `/projects/{project_id}/offerings` | `create-offering` | `project_configuration:offerings:read_write` |

## Package

| Method | Path | Operation | Permission scope |
|---|---|---|---|
| `GET` | `/projects/{project_id}/packages/{package_id}` | `get-package` | `project_configuration:packages:read` |
| `POST` | `/projects/{project_id}/packages/{package_id}` | `update-package` | `project_configuration:packages:read_write` |
| `DELETE` | `/projects/{project_id}/packages/{package_id}` | `delete-package-from-offering` | `project_configuration:packages:read_write` |
| `GET` | `/projects/{project_id}/offerings/{offering_id}/packages` | `list-packages` | `project_configuration:packages:read` |
| `POST` | `/projects/{project_id}/offerings/{offering_id}/packages` | `create-packages` | `project_configuration:packages:read_write` |
| `GET` | `/projects/{project_id}/packages/{package_id}/products` | `get-products-from-package` | `project_configuration:packages:read` |
| `POST` | `/projects/{project_id}/packages/{package_id}/actions/attach_products` | `attach-products-to-package` | `project_configuration:packages:read_write` |
| `POST` | `/projects/{project_id}/packages/{package_id}/actions/detach_products` | `detach-products-from-package` | `project_configuration:packages:read_write` |

## Paywall

| Method | Path | Operation | Permission scope |
|---|---|---|---|
| `POST` | `/projects/{project_id}/paywalls` | `create-paywall` | `project_configuration:offerings:read_write` |

## Customer

| Method | Path | Operation | Permission scope |
|---|---|---|---|
| `GET` | `/projects/{project_id}/customers` | `list-customers` | `customer_information:customers:read` |
| `POST` | `/projects/{project_id}/customers` | `create-customer` | `customer_information:customers:read_write` |
| `GET` | `/projects/{project_id}/customers/{customer_id}` | `get-customer` | `customer_information:customers:read` |
| `DELETE` | `/projects/{project_id}/customers/{customer_id}` | `delete-customer` | `customer_information:customers:read_write` |
| `POST` | `/projects/{project_id}/customers/{customer_id}/actions/transfer` | `transfer-customer-data` | `customer_information:customers:read_write; customer_information:subscriptions:read_write; customer_information:purchases:read_write` |
| `POST` | `/projects/{project_id}/customers/{customer_id}/actions/grant_entitlement` | `grant-customer-entitlement` | `customer_information:customers:read_write` |
| `POST` | `/projects/{project_id}/customers/{customer_id}/actions/revoke_granted_entitlement` | `revoke-customer-granted-entitlement` | `customer_information:customers:read_write` |
| `POST` | `/projects/{project_id}/customers/{customer_id}/actions/assign_offering` | `assign-customer-offering` | `project_configuration:offerings:read; customer_information:customers:read_write` |
| `GET` | `/projects/{project_id}/customers/{customer_id}/subscriptions` | `list-subscriptions` | `customer_information:subscriptions:read` |
| `GET` | `/projects/{project_id}/customers/{customer_id}/purchases` | `list-purchases` | `customer_information:purchases:read` |
| `GET` | `/projects/{project_id}/customers/{customer_id}/active_entitlements` | `list-customer-active-entitlements` | `customer_information:customers:read` |
| `GET` | `/projects/{project_id}/customers/{customer_id}/aliases` | `list-customer-aliases` | `customer_information:customers:read` |
| `GET` | `/projects/{project_id}/customers/{customer_id}/virtual_currencies` | `list-virtual-currencies-balances` | `customer_information:purchases:read` |
| `POST` | `/projects/{project_id}/customers/{customer_id}/virtual_currencies/transactions` | `create-virtual-currencies-transaction` | `customer_information:purchases:read_write` |
| `POST` | `/projects/{project_id}/customers/{customer_id}/virtual_currencies/update_balance` | `update-virtual-currencies-balance` | `customer_information:purchases:read_write` |
| `GET` | `/projects/{project_id}/customers/{customer_id}/attributes` | `list-customer-attributes` | `customer_information:customers:read` |
| `POST` | `/projects/{project_id}/customers/{customer_id}/attributes` | `set-customer-attributes` | `customer_information:customers:read_write` |

## Subscription

| Method | Path | Operation | Permission scope |
|---|---|---|---|
| `GET` | `/projects/{project_id}/subscriptions/{subscription_id}` | `get-subscription` | `customer_information:subscriptions:read` |
| `GET` | `/projects/{project_id}/subscriptions/{subscription_id}/transactions` | `get-play-store-subscription-transactions` | `customer_information:subscriptions:read` |
| `POST` | `/projects/{project_id}/subscriptions/{subscription_id}/transactions/{transaction_id}/actions/refund` | `refund-play-store-subscription-transaction` | `customer_information:subscriptions:read_write` |
| `GET` | `/projects/{project_id}/subscriptions/{subscription_id}/entitlements` | `list-subscription-entitlements` | `customer_information:subscriptions:read` |
| `POST` | `/projects/{project_id}/subscriptions/{subscription_id}/actions/cancel` | `cancel-subscription` | `customer_information:subscriptions:read_write` |
| `POST` | `/projects/{project_id}/subscriptions/{subscription_id}/actions/refund` | `refund-subscription` | `customer_information:subscriptions:read_write` |
| `GET` | `/projects/{project_id}/subscriptions/{subscription_id}/authenticated_management_url` | `get-authorized-subscription-management-url` | `customer_information:subscriptions:read` |
| `GET` | `/projects/{project_id}/subscriptions` | `search-subscriptions` | `customer_information:subscriptions:read` |

## Purchase

| Method | Path | Operation | Permission scope |
|---|---|---|---|
| `GET` | `/projects/{project_id}/purchases/{purchase_id}` | `get-purchase` | `customer_information:purchases:read` |
| `GET` | `/projects/{project_id}/purchases/{purchase_id}/entitlements` | `list-purchase-entitlements` | `customer_information:purchases:read` |
| `POST` | `/projects/{project_id}/purchases/{purchase_id}/actions/refund` | `refund-purchase` | `customer_information:purchases:read_write` |
| `GET` | `/projects/{project_id}/purchases` | `search-purchases` | `customer_information:purchases:read` |

## Invoice

| Method | Path | Operation | Permission scope |
|---|---|---|---|
| `GET` | `/projects/{project_id}/customers/{customer_id}/invoices` | `list-customer-invoices` | `customer_information:invoices:read` |
| `GET` | `/projects/{project_id}/customers/{customer_id}/invoices/{invoice_id}/file` | `get-invoice` | `customer_information:invoices:read` |

## Charts & Metrics

| Method | Path | Operation | Permission scope |
|---|---|---|---|
| `GET` | `/projects/{project_id}/metrics/overview` | `get-overview-metrics` | `charts_metrics:overview:read` |

## Integration

| Method | Path | Operation | Permission scope |
|---|---|---|---|
| `GET` | `/projects/{project_id}/integrations/webhooks` | `list-webhook-integrations` | `project_configuration:integrations:read` |
| `POST` | `/projects/{project_id}/integrations/webhooks` | `create-webhook-integration` | `project_configuration:integrations:read_write` |
| `GET` | `/projects/{project_id}/integrations/webhooks/{webhook_integration_id}` | `get-webhook-integration` | `project_configuration:integrations:read` |
| `POST` | `/projects/{project_id}/integrations/webhooks/{webhook_integration_id}` | `update-webhook-integration` | `project_configuration:integrations:read_write` |
| `DELETE` | `/projects/{project_id}/integrations/webhooks/{webhook_integration_id}` | `delete-webhook-integration` | `project_configuration:integrations:read_write` |


    ## Common payload templates in this skill

    - `assets/payloads/create-entitlement.json`
    - `assets/payloads/create-offering.json`
    - `assets/payloads/create-package.json`
    - `assets/payloads/create-product-test-store-subscription.json`
    - `assets/payloads/grant-entitlement.json`
    - `assets/payloads/set-customer-attributes.json`

    ## Practical patterns

    ### Create a product
    Required fields vary by product type and store. For common API-driven setups, provide:
    - `store_identifier`
    - `app_id`
    - `type`
    - optional `display_name`
    - optional `subscription.duration` for simulated or test-store subscriptions

    ### Create an entitlement
    Minimum body:
    - `lookup_key`
    - `display_name`

    ### Create an offering
    Minimum body:
    - `lookup_key`
    - `display_name`

    ### Create a package in an offering
    Minimum body:
    - `lookup_key`
    - `display_name`
    - optional `position`

    ### Attach products
    Entitlements and packages both support attach and detach actions with `product_ids`.

    ### Customer promotional access
    Granting an entitlement to a customer creates a promotional subscription as a side effect.
    Revoking it expires that promotional subscription.

    ### Search endpoints
    - purchases search by `store_purchase_identifier`
    - subscriptions search by `store_subscription_identifier`
