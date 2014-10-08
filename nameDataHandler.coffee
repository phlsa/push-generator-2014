parseNameData = (dataStr) ->
  persons = dataStr.split("***")
  return _.map persons, (person) ->
    raw = person.split(";")
    return {first: raw[1], last: raw[0], company: raw[2]}