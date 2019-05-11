var fs = require("fs");

// ファイル一覧
module.exports.getall = function(req, res, next) {
  console.log("OK");
  fs.readdir('log/', function(err, files) {
    if(err) throw err;
    res.json(files);
  });
}

// ファイルの中身取得
module.exports.get = function(req, res, next) {
  let filename = req.params.filename;
  console.log(filename);
  fs.readFile("log/" + filename, "utf8", (err, data) => {
    if(err) throw err;
    data = data.trim().split("\n");
    ret = {
      names: data[0].split(" "),
      result: data[1].split(" "),
      field: []
    };
    console.log(data.length);
    idx = 2;
    while(idx < data.length) {
      let turn = data[idx++];
      let left_times = data[idx++].split(" ");
      let levels = data[idx++].split(" ");
      let golds = data[idx++].split(" ");
      let shops = [[], []];
      for(let i = 0; i < 2; i++) {
        for(let j = 0; j < 3; j++) {
          let s = data[idx++].split(" ");
          shops[i].push({id: s[0], type: s[1], hp: s[2], atk: s[3], val: s[4]});
        }
      }
      let units = [[], []];
      for(let i = 0; i < 2; i++) {
        let n = Number(data[idx++]);
        while(n--) {
          let s = data[idx++].split(" ");
          units[i].push({team: i, id: s[0], type: s[1], hp: s[2], atk: s[3], x: s[4], y: s[5]});
        }
      }
      ret.field.push({
        turn: turn,
        levels: levels,
        left_times: left_times,
        golds: golds,
        shops: shops,
        units: units
      });
    }
    res.json(ret);
  });
}
