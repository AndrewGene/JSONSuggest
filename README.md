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

#Use the JSONSuggest API
By default, JSONSuggest is set to upload the generated classes to JSONSuggest.com so that it can create the file(s) for you so that you can easily download the files and drag-and-drop them into your project.

When using the API, JSONSuggest will generate a short-lived (1 hour) link and show it to you in the console. It will look like this...
![alt tag](https://github.com/AndrewGene/JSONSuggest/blob/master/XcodeConsole.png)

#Use the Xcode Console
Your code will simply be printed to the console.  You can then manually create your model files and copy/paste the contents.
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
#Example Output
##Features
##For a single object
###Optional init
###toJSON
###toJSONString

##For an array
###fromJSONArray
###toJSONArray
###toJSONString

#Configuration

#Extra Features
##findInJSON##
##fromJSONArray##

