require! <[fs request path]>

# data from http://data.gov.tw/node/5948
# http://data.gov.tw/iisi/logaccess?dataUrl=http%3A%2F%2Fdownload.post.gov.tw%2Fpost%2Fdownload%2FZip32_UTF8_10303.TXT&type=TXT&nid=5948

fetch = do
  path:
    txt: path.join(__dirname,\postcode.txt)
    json: path.join(__dirname, \postcode.json)
    detail: path.join(__dirname, \postcode-detail.json)
  nummap:
    src: <[０ １ ２ ３ ４ ５ ６ ７ ８ ９]>map(->new RegExp(it,"g"))
    des: <[0 1 2 3 4 5 6 7 8 9]>
    patch: ->
      for n,i in @src => it = it.replace n, @des[i]
      it
  src:
    \http://data.gov.tw/iisi/logaccess?dataUrl=http%3A%2F%2Fdownload.post.gov.tw%2Fpost%2Fdownload%2FZip32_UTF8_10303.TXT&type=TXT&nid=5948
  parse: (verbose=false) ->
    log = if verbose => console.log else (->)
    data = {}
    log "parsing postcode data..."
    lines = fs.read-file-sync @path.txt .toString!split \\n .map(-> it.trim!).filter(->it)
    # 郵遞區號 / 縣市島 / 鄉鎮市島 / 單雙全 / 範圍(optional)
    lines = lines.map -> 
      [it, /^(\d{5})(\S{3})(\S{2,3}\s+|\S{4})(\S+) *([雙單全連　]{1,2})?([^\(\)]*?)(\(.+\)?)?$/.exec it]
    failed = lines.filter -> !it.1
    if failed.length > 0 => 
      log "parsing failed in following lines:"
      log failed.join(\\n)
      log "please check if this is correct before continue."
      return
    for line in lines =>
      [code3, code5, county, town] = [line.1.1.substring(0,3), line.1.1, line.1.2, line.1.3]
      if !data[county] => data[county] = {}
      if !data[county][town] => data[county][town] = []
      if (data[county][town].indexOf(code3)==-1) => data[county][town].push code3
    for county of data =>
      for town of data[county] =>
        if data[county][town].length > 1 =>
          log "[Warning] #county #town has multiple postcodes(3): #{data[county][town].join " "}"
    log "basic county / town pair analysis complete, writing postcode.json..."
    fs.write-file-sync @path.json, JSON.stringify(data)
    for county of data => for town of data[county] => 
      data[county][town] = {brief: data[county][town], detail: {}}
    for line in lines =>
      [code3, code5, county, town] = [line.1.1.substring(0,3), line.1.1, line.1.2, line.1.3]
      [road, rule1, rule2] = [line.1.4, line.1.5, line.1.6.replace(/\s/g, "")]
      ret = /^(\D+?)([０-９]+段.*)?$/.exec road.trim!
      [road,sec] = if ret => [ret.1, @nummap.patch(ret.2 or "")] else [ret.1, ""]
      data[county][town]detail.{}[road][sec] = [rule1, rule2]
    fs.write-file-sync @path.detail, JSON.stringify(data)
    return data

  fetch: (verbose=false)->
    log = if verbose => console.log else (->)
    if fs.exists-sync @path.txt =>
      if verbose => log "postcode.txt found, use it directly."
      @parse verbose
    else
      if verbose => log "Downloading postcode data..."
      (e,r,b) <~ request do
        url: @src
        method: \GET
      if e => 
        log "failed: #e"
        return
      log "Done. Save it as postcode.txt."
      fs.write-file-sync @path.txt, b
      @parse verbose

fetch.fetch true
