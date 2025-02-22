# FlowerBreeder
TODO: come up with a better name!

This is a _Hello Kitty Island Adventure_ (HKIA) companion app to help you achieve your flower breeding goals and make Wish me mell mad jelly!

The idea is that, with HKIA running, you start a "Screen Broadcast" to the app, open up your inventory, and scroll through your flower inventory. This app will look at your flowers and automatically detect what it sees. It does the detection with AI, so it may get some things wrong. You'll be able to fix things, and it will flag flowers it's not sure about.

Now that it knows what flowers you have, it will be able to show you what kind of new flowers you can make, and the exact recipe of how to do it. It's also got a list of various goals you could work towards to **REALLY** impress Wish me mell.

This app is **heavily** inspired by _Poke Genie_, a companion app for _Pokemon Go_.

# FlowerLabeler
This is a companion macOS app to make setting up the data for the AI training process easier.

## Training Process

See [training-instructions.md](project-planning/cursor/training-instructions.md) for detailed steps on:
1. Gathering training data
2. Using FlowerLabeler (macOS app) to label images
3. Training the model in Create ML
4. Integrating the model into the iOS app
