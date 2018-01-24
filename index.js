"use strict";

const { router, get } = require("microrouter");

module.exports = router(
    get("/", function () { return "root"; }),
    get("/*", function () { return "path"; })
);
