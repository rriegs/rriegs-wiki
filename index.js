"use strict";

const fs = require("fs-extra");
const mime = require("mime");
const { router, get } = require("microrouter");

const getPath = async function (req, res) {
    let filePath = "www/" + (req.params._ || "index.html");
    let fileType = mime.getType(filePath) || "text/plain";
    res.setHeader("Content-Type", fileType);
    return await fs.readFile(filePath);
};

module.exports = router(
    get("/*", getPath)
);
