import type { ItemData, AdvancedItemData } from "./struct/ItemData"

const GearJson: Record<string, ItemData> = await Bun.file("Reference/gear.json").json()
const AdvancedGearJson: Record<string, AdvancedItemData> = await Bun.file("Reference/advanced_gear.json").json()

/*
    GearJson is from the Wynncraft API.
    AdvancedGearJson is a custom file that contains additional information about the gear.

    Loop through all items of GearJson. If the item is in AdvancedGearJson, merge the two objects, merge the objects. If its not, add the item to AdvancedGearJson.
*/

const TRANSFORMERS: Record<string, {from: string | undefined; to: string | undefined; delete: boolean; processor?: (to: string | any, value: string | any, object: any) => any; }> = {
    rarity: {
        from: "rarity",
        to: "tier",
        delete: true
    },
    health: {
        from: "base.baseHealth",
        to: "base.health",
        delete: true
    },
    armourType: {
        from: "armourType",
        to: "type",
        delete: true
    },
    weaponType: {
        from: "weaponType",
        to: "type",
        delete: true
    },
    color: {
        from: "armourMaterial",
        to: "armorType",
        delete: true,
        processor(to, value, object) {
            object[to] = value;
            if(value == "leather" && !object["armorColor"]) {
                object["armorColor"] = "160,101,64"
            }
        },
    },
    averageDPS: {
        from: "averageDps",
        to: "base.averageDPS",
        delete: true
    },
    baseDamage: {
        from: "base.baseDamage",
        to: "base.baseDamage",
        delete: false,
        processor(to, value, object) {
            nestedSet(object, to, { max: value, min: value })
        },
    },
    baseFireDamage: {
        from: "base.baseFireDamage",
        to: "base.fireDamage",
        delete: false,
        processor(to, value, object) {
            nestedSet(object, to, { max: value, min: value })
        },
    },
    baseAirDamage: {
        from: "base.baseAirDamage",
        to: "base.baseAirDamage",
        delete: false,
        processor(to, value, object) {
            nestedSet(object, to, { max: value, min: value })
        },
    },
    baseThunderDamage: {
        from: "base.baseThunderDamage",
        to: "base.baseThunderDamage",
        delete: true,
        processor(to, value, object) {
            nestedSet(object, to, { max: value, min: value })
        },
    },
    baseWaterDamage: {
        from: "base.baseWaterDamage",
        to: "base.baseWaterDamage",
        delete: false,
        processor(to, value, object) {
            nestedSet(object, to, { max: value, min: value })
        },
    },
    baseEarthDamage: {
        from: "base.baseEarthDamage",
        to: "base.baseEarthDamage",
        delete: false,
        processor(to, value, object) {
            nestedSet(object, to, { max: value, min: value })
        },
    },
    baseFireDefence: {
        from: "base.baseFireDefence",
        to: "base.fireDefence",
        delete: true
    },
    baseAirDefence: {
        from: "base.baseAirDefence",
        to: "base.airDefence",
        delete: true
    },
    baseThunderDefence: {
        from: "base.baseThunderDefence",
        to: "base.thunderDefence",
        delete: true
    },
    baseWaterDefence: {
        from: "base.baseWaterDefence",
        to: "base.waterDefence",
        delete: true
    },
    baseEarthDefence: {
        from: "base.baseEarthDefence",
        to: "base.earthDefence",
        delete: true
    },
    rawSkillStats: {
        from: undefined,
        to: undefined,
        delete: false,
        processor(to, value, object) {
            const rawStats = ["rawDefence", "rawStrength", "rawIntelligence", "rawDexterity", "rawAgility"]
            if(!value["identifications"]) return;
            if(!object["identifications"]) object["identifications"] = {}
            for (const stat of rawStats) {
                if (value["identifications"][stat] !== undefined && value["identifications"][stat].raw !== undefined) {
                    object["identifications"][stat] = value["identifications"][stat].raw
                }
            }
        },
    },
    deleteIcon: {
        from: "icon",
        to: undefined,
        delete: true,
        processor(to, value, object) {
            if(!object["material"]) {
                object["material"] = "256:10"
            }
        },
    },
    deleteClassRequirement: {
        from: "requirements.classRequirement",
        to: undefined,
        delete: true,
    },
    fixMinOrMaxMissing: {
        from: undefined,
        to: undefined,
        delete: false,
        processor(to, value, object) {
            if(!object["identifications"]) return;
            for(let identification of Object.keys(value["identifications"])) {
                if (object["identifications"][identification].min !== undefined && object["identifications"][identification].max === undefined) {
                    object["identifications"][identification]["max"] = object["identifications"][identification].min;
                }
                if(object["identifications"][identification].max !== undefined && object["identifications"][identification].min === undefined) {
                    object["identifications"][identification]["min"] = object["identifications"][identification].max;
                }
            }
        }
    }
}

function wynnFormatToAdvancedFormat (item: ItemData, existing?: AdvancedItemData): AdvancedItemData {
    let newItem: AdvancedItemData = {
        ...item,
        ...existing
    }

    for(const transformerName of Object.keys(TRANSFORMERS)) {
       const transformer = TRANSFORMERS[transformerName]

        if(!transformer.from || nestedGet(item, transformer.from) !== undefined) {
            const processor = transformer.processor ?? ((to, value, object) => {
                if(to != null && value != null) nestedSet(object, to, value) })
            processor(transformer.to, transformer.from != null ? nestedGet(item, transformer.from): item, newItem)

            if (transformer.delete && transformer.from) {
                nestedDelete(newItem, transformer.from)
            }
        }
    }

    return newItem
}

const nestedGet = (object: any, path: string) => path.split(".").reduce((acc, key) => acc != undefined ? acc[key] : acc, object)
const nestedSet = (object: any, path: string, value: any) => {
    const keys: string[] = path.split(".")
    const lastKey: string | undefined = keys.pop()
    const lastObject = keys.reduce((acc, key) => acc != undefined ? acc[key] : acc, object)
    if(lastKey)
        lastObject[lastKey] = value
}
const nestedDelete = (object: any, path: string) => {
    const keys: string[] = path.split(".")
    const lastKey: string | undefined = keys.pop()
    const lastObject = keys.reduce((acc, key) => acc[key], object)
    if(lastKey)
        delete lastObject[lastKey]
}

const filter = process.argv.length > 2 ? process.argv.slice(2) : undefined

console.log(Object.keys(GearJson).length)
for (const itemName of Object.keys(GearJson)) {
    if(filter && !filter.includes(itemName)) continue
    const newData = wynnFormatToAdvancedFormat(GearJson[itemName])
    if (itemName in AdvancedGearJson) {
        AdvancedGearJson[itemName] = {
            ...newData,
            ...AdvancedGearJson[itemName],
        }

    console.log(`Updated ${itemName}`)
    } else {
        AdvancedGearJson[itemName] = newData
        console.log(`Added ${itemName}`)
    }
}

await Bun.write("Reference/tmp/advanced_gear.json", JSON.stringify(AdvancedGearJson))
await Bun.write("Reference/tmp/advanced_gear_expanded.json", JSON.stringify(AdvancedGearJson, null, 2))

console.log("Done")

let md5 = (await Bun.$`md5sum Reference/advanced_gear.json | cut -d' ' -f1`.text()).replace("\n", "")

const URLJson: {md5: string; id: string}[] = await Bun.file("Data-Storage/urls.json").json()
URLJson.forEach(item => {
    if (item.id === "dataStaticGearAdvanced") {
        item.md5 = md5
    }
})

await Bun.write("Data-Storage/urls.json", JSON.stringify(URLJson, null, 2))
