![alt tag](https://github.com/AndrewGene/JSONSuggest/blob/master/JSONSUGGEST.png)
The easiest way to add models and JSON de/serialization to your Swift project.

#What is it
JSONSuggest reads the responses from any API and generates models (along with code to serialize / deserialize each object).  It also provides some extra features (see "Extra Features" below).

#Installation
While you are developing, simply add JSONSuggest.swift to your project.

If you decide to leave the file in after you are done developing, there is an *isDebug* variable you can set to **false** so that JSONSuggest will not run when your app is in production.

#Usage
Anywhere you are parsing JSON, simply add this line...
```swift
JSONSuggest.sharedSuggest.makeSuggestions(json)
```
Your models will then be generated.  You can either print them in the console or you can use JSONSuggest's API.

#Let's look at an example *Person* object
```javascript
{
    "firstName": "John",
    "lastName": "Smith",
    "age": 25,
    "phoneNumbers":
    [
      {
         "type": "home",
         "number": "212 555-1234"
      },
      {
         "type": "fax",
         "number": "646 555-4567"
      }
   ]
}
```
##De/Serialization Features
**For a single object**
###Optional init
```swift
init?(JSON:AnyObject?){
        var json = JSON
        if json != nil{
            if json is [String:AnyObject]{
                if let firstKey = (json as! [String:AnyObject]).keys.first{
                    if firstKey == "Person"{
                        json = json![firstKey]
                    }
                }

                guard
                    let age = json?["age"] as? Int,
                    let firstName = json?["firstName"] as? String,
                    let lastName = json?["lastName"] as? String,
                    let phoneNumbers = json?["phoneNumbers"] as? [[String:AnyObject]]
                else{
                    return nil
                }

                self.age = age
                self.firstName = firstName
                self.lastName = lastName
                self.phoneNumbers = phoneNumber.fromJSONArray(phoneNumbers)


            }
            else{
                return nil
            }
        }
        else{
            return nil
        }
    }
```
**Usage of init?()**
```swift
if let person = Person(JSON: json){
    //now you have a person object
}
```
JSONSuggest is smart enough to look through all of the objects in your JSON response to determine what is optional.  If a property is not always present, it is made an optional. Anything that isn't optional, is added to the guard statement at the top of the *init?()*. Obviously, this won't always be perfect but it is a VERY good head start.
###toJSON
```swift
var toJSON: [String:AnyObject] {
        var jsonObject = [String:AnyObject]()
        jsonObject["age"] = self.age
        jsonObject["firstName"] = self.firstName
        jsonObject["lastName"] = self.lastName
        jsonObject["phoneNumbers"] = self.phoneNumbers.toJSONArray

        return jsonObject
    }
```
**Usage of toJSON**
```swift
//person object from up above
person.toJSON
```
*.toJSON* takes a class object and converts it into [String:AnyObject] dictionary representation.  This is commonly used when sending the object in an API call.
###toJSONString
```swift
var toJSONString: String {
        var jsonString = ""
        jsonString += ", \"age\":\"\(self.age)\""
        jsonString += ", \"firstName\":\"\(self.firstName)\""
        jsonString += ", \"lastName\":\"\(self.lastName)\""
        jsonString += ", \"phoneNumbers\":\"\(self.phoneNumbers.toJSONString)\""

        jsonString = String(jsonString.characters.dropFirst()) //removes the ','
        jsonString = String(jsonString.characters.dropFirst()) //removes the beginning space

        return jsonString
    }
```
**Usage of toJSONString**
```swift
person.toJSONString
```
*.toJSONString* takes a class object and converts it into a String representation.  You can use this when sending an object in an API call (although much less common than .toJSON).

**For an array**
###fromJSONArray
```swift
class func fromJSONArray(JSON:[[String:AnyObject]]) -> [Person]{
        var returnArray = [Person]()
        for entry in JSON{
            if let ent = Person(JSON: entry){
                returnArray.append(ent)
            }
        }
        return returnArray
    }
```
**Usage of fromJSONArray**
```swift
let people = Person.fromJSONArray(json) //json is [[String:AnyObject]]
```
*.fromJSONArray* takes an array of dictionaries and attempts to convert them into an array of *Person* objects. **Note**: it is a class function so you do **not** need to instantiate a *Person* object before you use it.

###toJSONArray
```swift
var toJSONArray : [[String:AnyObject]]{
        var returnArray = [[String:AnyObject]]()
        for entry in self{
            returnArray.append(entry.toJSON)
        }
        return returnArray
    }
```
**Usage of toJSONArray**
```swift
//people is the same object created by fromJSONArray
people.toJSONArray
```
*.toJSONArray* takes an array of *Person* objects and converts it into an array of dictionaries ( [[String:AnyObject]] ).
###toJSONString
```swift
var toJSONString : String{
        var returnString = ""
        for entry in self{
            returnString += entry.toJSONString
        }
        return returnString
    }
```
**Usage of toJSONString**
```swift
people.toJSONString
```
*.toJSONString* takes an array of *Person* objects and converts it into a String.

#Extra Features
##findInJSON##
```swift
func findInJSON(JSON:AnyObject, complete:((persons:[Person])->())?){
        var persons = [Person]()
        traverseJSON(&persons, JSON: JSON) { (persons) in
            if complete != nil{
                complete!(persons: persons)
            }
        }
    }
```
**Usage of findInJSON**
```swift
Person().findInJSON(json, complete: { (people) in
     if people.count > 0{
        //you have an array of People objects
     }
     else{
        print("no people found")
     }
})
```
*.findInJSON* allows you to traverse the entire JSON response back from the API and find all of the *Person* objects that it contains (even if they are within different objects entirely).

#Use the JSONSuggest API
By default, JSONSuggest is set to upload the generated classes to JSONSuggest.com so that it can create the file(s) for you so that you can easily download the files and drag-and-drop them into your project.

When using the API, JSONSuggest will generate a short-lived (1 hour) link and show it to you in the console. It will look like this...
![alt tag](https://github.com/AndrewGene/JSONSuggest/blob/master/XcodeConsole.png)

#Use the Xcode Console
Your code will simply be printed to the console.  You can then manually create your model files and copy/paste the contents.


#Configuration



