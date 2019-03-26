# **BuffCheck2**
Wow 1.12 addon to monitor consumes

![alt text](https://i.imgur.com/7aJgBJ4.png)

**Usage:**<br/>
Add each consume using the add command below. The interface will only display an icon of 
the consume when the consume is not active. Right clicking the icon uses the consume. 
If there is nothing to display the interface will display a placeholder and update again when a consume expires.

Also gives a five or two minute expiration warning based on the consumes duration. Two minutes for consumes with duration 15min or less, five minutes otherwise.
Then gives another message when the consume expires.

Currently supports most* consumes, food buffs, and weapon buffs. If you find one missing
feel free to add it to BuffCheck2_Data.lua or contact me to have it added.

**Commands:**<br/>
/bc2 **add** [**ItemLink**]
  - adds the linked item to be monitored

/bc2 **remove** [**ItemLink**]
  
  - removes the linked item

/bc2 **show**
  
  - shows the interface
  
/bc2 **hide**

   - hides the interface
   
/bc2 **lock**

   - locks the interface
   
/bc2 **unlock**

   - unlocks the interface
   
/bc2 **scale** {**number**}

   - scales the interface, default is 100

/bc2 **clear**

  - clears the list of saved consumes

This addon was made by Kaymon \<Scuba Cops> for the Northdale Vanilla private server. If you find
any bugs or issues with the addon contact him in game.