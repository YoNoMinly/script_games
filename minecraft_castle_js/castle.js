player.teleport(pos(0, 0, 0));


let startX = 10;
let startY = 0;
let startZ = 10;

let stones = [STONE_BRICKS, CRACKED_STONE_BRICKS, MOSSY_STONE_BRICKS, COBBLESTONE, POLISHED_ANDESITE];


for (let x = -4; x < 24; x++) {
    for (let z = -4; z < 24; z++) {
        if (x < 0 || x > 19 || z < 0 || z > 19) {
            blocks.place(WATER, pos(startX + x, startY - 1, startZ + z));
        }
    }
}


for (let x = -4; x < 24; x++) {
    for (let z of [-5, 23]) {
        for (let w = 0; w < 2; w++) {

            if ((z === -5) && (x >= 8 && x <= 11)) continue;

            let height = Math.randomRange(2, 5);
            for (let y = 0; y < height; y++) {
                let randomStone = stones[Math.randomRange(0, stones.length - 1)];
                blocks.place(randomStone, pos(startX + x, startY + y, startZ + z + w));
            }
        }
    }
}
for (let z = -4; z < 24; z++) {
    for (let x of [-5, 23]) {
        for (let w = 0; w < 2; w++) {
            let height = Math.randomRange(2, 5);
            for (let y = 0; y < height; y++) {
                let randomStone = stones[Math.randomRange(0, stones.length - 1)];
                blocks.place(randomStone, pos(startX + x + w, startY + y, startZ + z));
            }
        }
    }
}



for (let x = 0; x < 20; x++) {
    for (let z = 0; z < 20; z++) {
        for (let y = 0; y < 10; y++) {
            let isWall = (x === 0 || x === 19 || z === 0 || z === 19);
            let skipGate = (z === 0 && (x === 9 || x === 10) && (y === 1 || y === 2));
            let isWindow = false;


            if (
                ((y === 2 || y === 3) || (y === 7 || y === 8)) &&
                (
                    ((z === 0 || z === 19) && (x === 4 || x === 5 || x === 14 || x === 15)) ||
                    ((x === 0 || x === 19) && (z === 4 || z === 5 || z === 14 || z === 15))
                )
            ) {
                isWindow = true;
            }

            if (isWall && !skipGate) {
                if (isWindow) {
                    blocks.place(GLASS, pos(startX + x, startY + y, startZ + z));
                } else {
                    let randomStone = stones[Math.randomRange(0, stones.length - 1)];
                    blocks.place(randomStone, pos(startX + x, startY + y, startZ + z));
                }
            }
        }
    }
}


for (let x = 1; x < 19; x++) {
    for (let z = 1; z < 19; z++) {
        blocks.place(PLANKS_OAK, pos(startX + x, startY, startZ + z));
    }
}


for (let x = -1; x < 21; x++) {
    for (let z = -1; z < 21; z++) {
        blocks.place(STONE_BRICKS, pos(startX + x, startY + 10, startZ + z));
    }
}

for (let x = -1; x < 21; x++) {
    for (let z = -1; z < 21; z++) {

        let isStairsHole = (x >= 8 && x <= 11 && z >= 6 && z <= 11); // Тут можна змінювати значення для більших/менших отворів


        if (!isStairsHole) {
            blocks.place(STONE_BRICKS, pos(startX + x, startY + 5, startZ + z));
        }
    }
}


for (let i = 0; i < 5; i++) {
    for (let x = 8; x <= 11; x++) {
        for (let z = 9; z <= 10; z++) {
            blocks.place(STONE_BRICKS, pos(startX + x, startY + i, startZ + z - i));
        }
    }
}




blocks.place(STONE_BRICKS, pos(startX + 8, startY, startZ - 1));
blocks.place(STONE_BRICKS, pos(startX + 11, startY, startZ - 1));
blocks.place(STONE_BRICKS, pos(startX + 8, startY + 1, startZ - 1));
blocks.place(STONE_BRICKS, pos(startX + 11, startY + 1, startZ - 1));
blocks.place(STONE_BRICKS, pos(startX + 8, startY + 2, startZ - 1));
blocks.place(STONE_BRICKS, pos(startX + 9, startY + 3, startZ - 1));
blocks.place(STONE_BRICKS, pos(startX + 10, startY + 3, startZ - 1));
blocks.place(STONE_BRICKS, pos(startX + 11, startY + 2, startZ - 1));

blocks.place(STONE_BRICKS, pos(startX + 8, startY, startZ - 2));
blocks.place(STONE_BRICKS, pos(startX + 11, startY, startZ - 2));
blocks.place(STONE_BRICKS, pos(startX + 8, startY + 1, startZ - 2));
blocks.place(STONE_BRICKS, pos(startX + 11, startY + 1, startZ - 2));
blocks.place(STONE_BRICKS, pos(startX + 8, startY + 2, startZ - 2));
blocks.place(STONE_BRICKS, pos(startX + 9, startY + 3, startZ - 2));
blocks.place(STONE_BRICKS, pos(startX + 10, startY + 3, startZ - 2));
blocks.place(STONE_BRICKS, pos(startX + 11, startY + 2, startZ - 2));


let towers = [
    [-1, -2, -1],
    [-1, -2, 18],
    [18, -2, -1],
    [18, -2, 18]
];

for (let t of towers) {
    let baseX = t[0];
    let baseY = t[1];
    let baseZ = t[2];

    for (let x = baseX; x < baseX + 3; x++) {
        for (let z = baseZ; z < baseZ + 3; z++) {
            for (let y = 0; y < 13; y++) {
                blocks.place(LOG_OAK, pos(startX + x, startY + y, startZ + z));
            }
        }
    }

    for (let x = baseX; x < baseX + 3; x++) {
        for (let z = baseZ; z < baseZ + 3; z++) {
            blocks.place(STONE_BRICKS, pos(startX + x, startY + 13, startZ + z));
        }
    }

    for (let x = baseX - 1; x < baseX + 4; x++) {
        for (let z = baseZ - 1; z < baseZ + 4; z++) {
            let isEdge = (x === baseX - 1 || x === baseX + 3 || z === baseZ - 1 || z === baseZ + 3);
            if (isEdge && (x + z) % 2 === 0) {
                blocks.place(STONE_BRICKS, pos(startX + x, startY + 14, startZ + z));
            }
        }
    }
}


for (let z = -4; z < 0; z++) {
    blocks.place(PLANKS_OAK, pos(startX + 8, startY - 1, startZ + z));
    blocks.place(PLANKS_OAK, pos(startX + 10, startY, startZ + z));
    blocks.place(PLANKS_OAK, pos(startX + 9, startY, startZ + z));
    blocks.place(PLANKS_OAK, pos(startX + 11, startY - 1, startZ + z));
}


let archX = startX + 8; 
let archY = startY;     
let archZ = startZ - 3; 


for (let dz = 0; dz <= 1; dz++) {
    for (let y = 0; y <= 7; y++) {
        blocks.place(STONE_BRICKS, pos(archX, archY + y, archZ + dz));     
        blocks.place(STONE_BRICKS, pos(archX + 3, archY + y, archZ + dz)); 
    }

    blocks.place(STONE_BRICKS, pos(archX + 1, archY + 6, archZ + dz));
    blocks.place(STONE_BRICKS, pos(archX + 2, archY + 6, archZ + dz));

    blocks.place(STONE_BRICKS, pos(archX + 1, archY + 7, archZ + dz));
    blocks.place(STONE_BRICKS, pos(archX + 2, archY + 7, archZ + dz));

    blocks.place(CHISELED_STONE_BRICKS, pos(archX + 1, archY + 8, archZ + dz));
    blocks.place(CHISELED_STONE_BRICKS, pos(archX + 2, archY + 8, archZ + dz));
}


blocks.place(TORCH, pos(startX + 5, startY + 1, startZ + 5)); 
blocks.place(TORCH, pos(startX + 5, startY + 6, startZ + 5)); 




blocks.place(GLASS, pos(startX + 9, startY + 4, startZ));
blocks.place(GLASS, pos(startX + 10, startY + 4, startZ));
