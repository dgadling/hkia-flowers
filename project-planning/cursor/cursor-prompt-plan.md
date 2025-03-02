# Starting again with claude-3.7-sonnet-thinking
## **Prompt 1: Start with the development flow**
```text
------------------------------------------------------------------------------------------------------------------------
# Overall Goal #
There is an iOS Game, "Hello Kitty Adventure Island" ("HKIA") that has in-game flower breeding as part of the game. Flowers in the game reproduce into different colors and species-specific patterns. I know the rules for how the flowers mix to create new ones.

Our goal is to end up with a companion iOS app ("FlowerFriend" or "FF") with the following features.
1. **ML**: Bundled into it, a ML model that can look at a frame from HKIA and figure out which flowers are present.
2. **Screen Recording**: It is a "Screen Recording" target.
    A. The user can have HKIA running in the foreground and send pictures of the game to FF.
    B. FF will use an ML model to look at the pictures it receives and record an inventory of flowers.
    C. FF will send a notification that the user, while they are still active in HKIA, if it needs the user to do anything to get more accurate information.
3. **Inventory & completion**: There will be a tab for the current inventory to be viewed and edited by the user. The user should also be able to create/update/delete items from the inventory. It should be sortable and filterable.
4. **Progress & achievement**:  There will be a tab or something similar to show progress towards various goals. I will add the logic for that later if you create the structure.
5. **Planning & possibilities**: There will be a tab to show what kinds of flowers the player could create, given their current inventory. I can create the logic for that once you create the structure.

# Development Process #
1. **Skeleton**: I've already created the skeleton of the XCode project. Let me know immediately if you cannot see all the files. There are 12 files in the XCode project.
2. **ML Training**: Since we need to train an ML model, we will need samples to train it on.
    2.1 Let's make a version of FF that achieves goal #2 ("Screen Recording"). It should **also**, only when in "Developer mode", save the screen recording samples somewhere I can access them from the Finder when the iOS device is connected to my Mac.
    2.2 Let's make a companion MacOS app (FlowerLabeler) that will
        2.2.1 Load up the screen recording samples
        2.2.2 Show them to us 1-by-1 allowing us to label the screen recording samples with which flowers are present by drawing rectangles around them.
        2.2.3 Once finished, have an "Export" button that will bundle up the samples and labelling information in a format that "Create ML" will be able to take.
    2.3 Use Create ML to make the ML model, using our exported data.
3. Extend FF so that it records the inventory of flowers as it's sent data via Screen Recording
4. Extend FF to display that inventory of flowers.

We're developing this in XCode 16 using Cursor. Please review everything in the repo, all available API, XCode, and OS docs, and tell me how to proceed.
```
