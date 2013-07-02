# Islay Integration

Not exciting by itself, this app is only used to test the integration of the different Islay engines.

## Development and Testing 

This project contains the tests for each particular Engine which integrates with the core Islay Engine. The `development` branch on this project corresponds to the `development` branch on each engine. Where new work on an engine is being done in a feature branch, there must be a corresponding branch in this project.

For example, if in the IslayShop engine there was a branch called `manufacturers` there should be a corresponding branch in this project called `islay_shop_manufacturers`.

Once the work is completed, `manufacturers` in IslayShop is merged to `development` and `islay_shop_manufacturers` is merged to `development` in this project.

Integration's `master` branch should be kept in sync with the `master` branches of each project.
