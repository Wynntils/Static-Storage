import { write } from "bun";

const OldData = await Bun.file("Reference/tmp/old/advanced_gear.json").json();
const NewData = await Bun.file("Reference/tmp/advanced_gear.json").json();

for (const itemName of Object.keys(OldData)) {
    const data = OldData[itemName];
    if(NewData[itemName]?.material == "256:10") {
        NewData[itemName].material = data.material
    }
}

await Bun.write("Reference/tmp/advanced_gear_expanded.json", JSON.stringify(NewData, null, 2))
await Bun,write("Reference/tmp/advanced_gear.json", JSON.stringify(NewData))
