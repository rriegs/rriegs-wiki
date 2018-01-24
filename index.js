"use strict";

const fs = require("fs-extra");
const { router, get } = require("microrouter");

const getFile = async function (path) {
    return await fs.readFile("www/" + path, "utf8");
};

module.exports = router(
    get("/", function () { return getFile("index.html"); }),
    get("/*", function (req) { return getFile(req.params._);} )
);
