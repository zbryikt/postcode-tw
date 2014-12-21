require! <[fs]>
lines = fs.read-file-sync(\postcode.txt).toString!split \\n .filter(->it)map(->it.trim!)
hash = {}

nummap = src: <[０ １ ２ ３ ４ ５ ６ ７ ８ ９]>map(->new RegExp(it,"g")), des: <[0 1 2 3 4 5 6 7 8 9]>
nummap.patch = -> 
  for n,i in nummap.src => it = it.replace n, nummap.des[i]
  it

lines = lines.map (line) ->
  ret = /^(\d{5})(\S{3})(\S{2,3}\s+|\S{4})(\S+)([０-９]+段)? *([雙單全連　]{1,2})?([^\(\)]*?)(\(.+\)?)?$/.exec line
  code = ret.1
  county = ret.2
  town = ret.3
  street = ret.4
  sec = if ret.5 => nummap.patch ret.5 else null
  rule1 = ret.6
  if ret.7 =>
    rule2 = ret.7.replace(/\s/g, "")
    rule2 = rule2.replace(/\d+/g, "-")
    hash[rule2] = 1

#hash = {}
#lines.map -> hash[it] = 1
#console.log [k for k of hash].join("/")
console.log ["[#k]" for k of hash].join("\n")
h2 = {}
for k of hash =>
  for i from 0 til k.length =>
    h2[k.charAt(i)] = 1
console.log ["[#k]" for k of h2].join("\n")
