require! <[fs request]>

# data from http://data.gov.tw/node/5948
# http://data.gov.tw/iisi/logaccess?dataUrl=http%3A%2F%2Fdownload.post.gov.tw%2Fpost%2Fdownload%2FZip32_UTF8_10303.TXT&type=TXT&nid=5948

parser = ->
  data = {}
  console.log "parsing postcode data..."
  lines = fs.read-file-sync \postcode.txt .toString!split \\n .map(-> it.trim!).filter(->it)
  #lines = lines.map -> /^(\d{5})(..[市縣])(\S+)\s+(\S+)\s+(\S+)\s*(.+)?$/.exec it
  # 郵遞區號 / 縣市島 / 鄉鎮市島 / 單雙全 / 範圍(optional)
  lines = lines.map -> [it, /^(\d{5})(..[市縣台島])(\S+)\s+(\S+)\s*(.+)?$/.exec it]
  failed = lines.filter -> !it.1
  if failed.length > 0 => 
    console.log "parsing failed in following lines:"
    console.log failed.join(\\n)
    console.log "please check if this is correct before continue."
    return
  for line in lines =>
    [code3, code5, county, town] = [line.1.1.substring(0,3), line.1.1, line.1.2, line.1.3]
    if !data[county] => data[county] = {}
    if !data[county][town] => data[county][town] = []
    if (data[county][town].indexOf(code3)==-1) => data[county][town].push code3
  for county of data =>
    for town of data[county] =>
      if data[county][town].length > 1 =>
        console.log "[Warning] #county #town has multiple postcodes(3): #{data[county][town].join " "}"
  console.log "basic county / town pair analysis complete, writing postcode.json..."
  fs.write-file-sync \postcode.json, JSON.stringify(data)

if fs.exists-sync \postcode.txt =>
  console.log "postcode.txt found, use it directly."
  parser!
else
  console.log "Downloading postcode data..."
  (e,r,b) <- request do
    url: \http://data.gov.tw/iisi/logaccess?dataUrl=http%3A%2F%2Fdownload.post.gov.tw%2Fpost%2Fdownload%2FZip32_UTF8_10303.TXT&type=TXT&nid=5948
    method: \GET
  console.log "Done. Save it as postcode.txt."
  fs.write-file-sync \postcode.txt, b
  parser!
