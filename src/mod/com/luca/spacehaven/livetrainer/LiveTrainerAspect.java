/*
 * Space Haven Live Trainer
 * Author: Luca Cococcioni
 * License: MIT
 */
package com.luca.spacehaven.livetrainer;

import com.badlogic.gdx.Input;
import com.badlogic.gdx.utils.Array;
import fi.bugbyte.framework.Game;
import fi.bugbyte.framework.Gamestate;
import fi.bugbyte.spacehaven.HavenGameState;
import fi.bugbyte.spacehaven.SpaceHavenSettings;
import fi.bugbyte.spacehaven.ai.TradingHelper;
import fi.bugbyte.spacehaven.stuff.Character;
import fi.bugbyte.spacehaven.stuff.Properties;
import fi.bugbyte.spacehaven.stuff.Research;
import fi.bugbyte.spacehaven.stuff.personality.AbsWorkPersonality;
import fi.bugbyte.spacehaven.stuff.personality.AbstractPersonality;
import fi.bugbyte.spacehaven.stuff.personality.Personality;
import fi.bugbyte.spacehaven.stuff.personality.PersonalitySetting;
import fi.bugbyte.spacehaven.world.Ship;
import fi.bugbyte.spacehaven.world.World;
import fi.bugbyte.spacehaven.world.elements.Storage;
import org.aspectj.lang.annotation.After;
import org.aspectj.lang.annotation.Aspect;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketTimeoutException;
import java.util.HashMap;
import java.util.Base64;
import java.util.Collections;
import java.lang.reflect.Field;
import java.util.Map;
import java.util.concurrent.ConcurrentLinkedQueue;

@Aspect
public class LiveTrainerAspect {
    private static final String VERSION = "0.8.1";
    private static final int GUI_PORT = 17840;
    private static final int CREDIT_BONUS = 100000;
    private static final int HYPERFUEL_ID = 178;
    private static final int HYPERFUEL_BONUS = 50;

    private static final int[] INFINITE_RESOURCE_IDS = new int[] {
        15, 16, 157, 158, 162, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179,
        184, 706, 707, 712, 930, 1759, 1873, 1874, 1886, 1919, 1920, 1921, 1922,
        1924, 1925, 1926, 1932, 1946, 1947, 2053, 2058, 2475, 2657, 3196, 3366,
        3378, 3419, 3512, 3513, 4005, 4006, 4007, 4027, 4028, 4030
    };

    private static final long MAINTENANCE_INTERVAL_NS = 150000000L;
    private static final long TELEMETRY_INTERVAL_NS = 250000000L;
    private static final long RICH_TELEMETRY_INTERVAL_NS = 1500000000L;

    private static boolean infiniteResources = false;
    private static boolean infiniteHealth = false;
    private static boolean infiniteOxygen = false;
    private static boolean stableFood = false;
    private static boolean stableRest = false;
    private static boolean stableMood = false;
    private static boolean stableComfort = false;
    private static boolean instantResearch = false;
    private static World infiniteTrackedWorld = null;
    private static final Map<Integer, Integer> infiniteResourceFloors = new HashMap<Integer, Integer>();
    private static long nextMaintenanceNs = 0L;
    private static long nextTelemetryNs = 0L;
    private static long nextRichTelemetryNs = 0L;

    private static volatile boolean telemetryWorldLoaded = false;
    private static volatile int telemetryCredits = 0;
    private static volatile int telemetryHyperfuel = 0;
    private static volatile String telemetryShipName = "-";
    private static volatile int telemetryCrewCount = 0;
    private static volatile String telemetryCrewList = "CREWLIST|";
    private static volatile String telemetryTechList = "TECHLIST|";
    private static volatile Map<Integer, String> telemetryCrewDetails = Collections.emptyMap();
    private static volatile int telemetryResearchDone = 0;
    private static volatile int telemetryResearchTotal = 0;

    private static Field propertyValueField = null;
    private static boolean propertyValueFieldLookupDone = false;

    private static final ConcurrentLinkedQueue<TrainerCommand> COMMAND_QUEUE =
        new ConcurrentLinkedQueue<TrainerCommand>();

    private static final LiveTrainerAspect INSTANCE = new LiveTrainerAspect();

    static {
        startGuiServer();
    }

    public static LiveTrainerAspect aspectOf() {
        return INSTANCE;
    }

    public static boolean hasAspect() {
        return true;
    }

    @After(
        value = "execution(boolean fi.bugbyte.spacehaven.Input.keyDown(int)) && args(keycode)",
        argNames = "keycode"
    )
    public void afterKeyDown(int keycode) {
        if (keycode != Input.Keys.F1 && keycode != Input.Keys.F2 && keycode != Input.Keys.F3
                && keycode != Input.Keys.F4 && keycode != Input.Keys.F5
                && keycode != Input.Keys.F6 && keycode != Input.Keys.F7
                && keycode != Input.Keys.F8 && keycode != Input.Keys.F9
                && keycode != Input.Keys.F10) {
            return;
        }

        try {
            World world = getLoadedWorld();
            if (world == null) {
                log(keyName(keycode) + " ignored: no loaded Space Haven world.");
                return;
            }

            if (keycode == Input.Keys.F1) {
                addCredits(world, CREDIT_BONUS, "F1");
            } else if (keycode == Input.Keys.F2) {
                addResourceLive(world, HYPERFUEL_ID, HYPERFUEL_BONUS, "F2 Hyperfuel");
            } else if (keycode == Input.Keys.F3) {
                setInfiniteResources(world, !infiniteResources, "F3");
            } else if (keycode == Input.Keys.F4) {
                setInfiniteHealth(world, !infiniteHealth, "F4");
            } else if (keycode == Input.Keys.F5) {
                setInfiniteOxygen(world, !infiniteOxygen, "F5");
            } else if (keycode == Input.Keys.F6) {
                setStableFood(world, !stableFood, "F6");
            } else if (keycode == Input.Keys.F7) {
                setStableRest(world, !stableRest, "F7");
            } else if (keycode == Input.Keys.F8) {
                setStableMood(world, !stableMood, "F8");
            } else if (keycode == Input.Keys.F9) {
                setStableComfort(world, !stableComfort, "F9");
            } else if (keycode == Input.Keys.F10) {
                setInstantResearch(world, !instantResearch, "F10");
            }
        } catch (Throwable t) {
            System.err.println("[SpaceHavenLiveTrainer] Error while handling " + keyName(keycode) + ": " + t);
            t.printStackTrace();
        }
    }

    @After(
        value = "execution(void fi.bugbyte.spacehaven.HavenGameState.updateLogic(float)) && this(state)",
        argNames = "state"
    )
    public void afterUpdateLogic(HavenGameState state) {
        if (state == null) {
            return;
        }

        try {
            World world = state.getCurrentWorld();
            if (world == null) {
                telemetryWorldLoaded = false;
                telemetryShipName = "-";
                telemetryCrewCount = 0;
                telemetryCrewList = "CREWLIST|";
                telemetryTechList = "TECHLIST|";
                telemetryCrewDetails = Collections.emptyMap();
                telemetryResearchDone = 0;
                telemetryResearchTotal = 0;
                return;
            }

            processQueuedCommands(world);

            long now = System.nanoTime();
            if ((infiniteResources || infiniteHealth || infiniteOxygen || stableFood
                    || stableRest || stableMood || stableComfort || instantResearch)
                    && now >= nextMaintenanceNs) {
                nextMaintenanceNs = now + MAINTENANCE_INTERVAL_NS;

                if (infiniteResources) {
                    if (world != infiniteTrackedWorld) {
                        captureInfiniteResourceFloors(world);
                    }
                    maintainInfiniteResourceFloors(world);
                }

                if (infiniteHealth) {
                    maintainInfiniteHealth(world);
                }

                if (infiniteOxygen) {
                    maintainInfiniteOxygen(world);
                }
                if (stableFood) {
                    maintainStableFood(world);
                }
                if (stableRest) {
                    maintainStableRest(world);
                }
                if (stableMood) {
                    maintainStableMood(world);
                }
                if (stableComfort) {
                    maintainStableComfort(world);
                }
                if (instantResearch) {
                    maintainInstantResearch(world);
                }
            }

            if (now >= nextTelemetryNs) {
                nextTelemetryNs = now + TELEMETRY_INTERVAL_NS;
                updateTelemetry(world);
            }
            if (now >= nextRichTelemetryNs) {
                nextRichTelemetryNs = now + RICH_TELEMETRY_INTERVAL_NS;
                updateRichTelemetry(world);
            }
        } catch (Throwable t) {
            System.err.println("[SpaceHavenLiveTrainer] updateLogic error: " + t);
            t.printStackTrace();
        }
    }

    private static void processQueuedCommands(World world) {
        TrainerCommand cmd;
        int safety = 0;
        while ((cmd = COMMAND_QUEUE.poll()) != null && safety++ < 32) {
            try {
                if ("ADD_CREDITS".equals(cmd.action)) {
                    int amount = clamp(cmd.amount, 1, 2000000000);
                    addCredits(world, amount, "GUI");
                } else if ("ADD_RESOURCE".equals(cmd.action)) {
                    int resourceId = Math.max(1, cmd.resourceId);
                    int amount = clamp(cmd.amount, 1, 1000000);
                    addResourceLive(world, resourceId, amount, "GUI");
                } else if ("SET_INFINITE_RESOURCES".equals(cmd.action)) {
                    setInfiniteResources(world, cmd.enabled, "GUI");
                } else if ("SET_INFINITE_HEALTH".equals(cmd.action)) {
                    setInfiniteHealth(world, cmd.enabled, "GUI");
                } else if ("SET_INFINITE_OXYGEN".equals(cmd.action)) {
                    setInfiniteOxygen(world, cmd.enabled, "GUI");
                } else if ("SET_STABLE_FOOD".equals(cmd.action)) {
                    setStableFood(world, cmd.enabled, "GUI");
                } else if ("SET_STABLE_REST".equals(cmd.action)) {
                    setStableRest(world, cmd.enabled, "GUI");
                } else if ("SET_STABLE_MOOD".equals(cmd.action)) {
                    setStableMood(world, cmd.enabled, "GUI");
                } else if ("SET_STABLE_COMFORT".equals(cmd.action)) {
                    setStableComfort(world, cmd.enabled, "GUI");
                } else if ("SET_INSTANT_RESEARCH".equals(cmd.action)) {
                    setInstantResearch(world, cmd.enabled, "GUI");
                } else if ("COMPLETE_TECH".equals(cmd.action)) {
                    completeResearchTech(world, cmd.targetId, "GUI");
                } else if ("COMPLETE_ALL_TECH".equals(cmd.action)) {
                    completeAllVisibleResearch(world, "GUI");
                } else if ("APPLY_CREW".equals(cmd.action)) {
                    applyCrewEdits(world, cmd.targetId, cmd.payloadA, cmd.payloadB);
                } else if ("MAX_CREW_SKILLS".equals(cmd.action)) {
                    maxCrewSkills(world, cmd.targetId);
                } else if ("MAX_CREW_ATTRS".equals(cmd.action)) {
                    maxCrewAttributes(world, cmd.targetId);
                } else if ("CURE_CREW_NEGATIVE".equals(cmd.action)) {
                    cureNegativeConditions(world, cmd.targetId);
                }
            } catch (Throwable t) {
                System.err.println("[SpaceHavenLiveTrainer] GUI command error: " + t);
                t.printStackTrace();
            }
        }
    }

    private static void setInfiniteResources(World world, boolean enabled, String source) {
        infiniteResources = enabled;
        nextMaintenanceNs = 0L;

        if (infiniteResources) {
            captureInfiniteResourceFloors(world);
            log(source + ": Infinite Resources ON. Protected " + infiniteResourceFloors.size()
                + " resource types at their current total quantities.");
        } else {
            infiniteTrackedWorld = null;
            infiniteResourceFloors.clear();
            log(source + ": Infinite Resources OFF.");
        }
    }

    private static void setInfiniteHealth(World world, boolean enabled, String source) {
        infiniteHealth = enabled;
        nextMaintenanceNs = 0L;
        log(source + ": Infinite Health " + (enabled ? "ON (smooth regeneration)." : "OFF."));
    }

    private static void setInfiniteOxygen(World world, boolean enabled, String source) {
        infiniteOxygen = enabled;
        nextMaintenanceNs = 0L;
        log(source + ": Infinite Oxygen " + (enabled ? "ON (smooth recovery)." : "OFF."));
    }

    private static void maintainInfiniteHealth(World world) {
        Array<Ship> ships = world.getShips();
        if (ships == null) {
            return;
        }

        for (Ship ship : ships) {
            if (ship == null || !ship.isPlayerShip()) {
                continue;
            }

            Array<Character> chars = ship.getCharacters();
            if (chars == null) {
                continue;
            }

            for (Character character : chars) {
                if (character == null || !character.isPlayerChar()) {
                    continue;
                }

                Properties.HealthProperty health = character.getHealthProp();
                if (health == null) {
                    continue;
                }

                int current = health.getValue();
                int max = health.getMax();

                // Do not resurrect an already dead character in this first live build.
                if (current <= 0 || max <= 0 || current >= max) {
                    continue;
                }

                // Smooth regeneration: up to 4 health points every maintenance tick.
                int heal = Math.min(4, max - current);
                health.setValue(current + heal);
            }
        }
    }

    private static void maintainInfiniteOxygen(World world) {
        Array<Ship> ships = world.getShips();
        if (ships == null) {
            return;
        }

        for (Ship ship : ships) {
            if (ship == null || !ship.isPlayerShip()) {
                continue;
            }

            Array<Character> chars = ship.getCharacters();
            if (chars == null) {
                continue;
            }

            for (Character character : chars) {
                if (character == null || !character.isPlayerChar()) {
                    continue;
                }

                Properties.OxygenProperty oxygen = character.getOxygenProp();
                if (oxygen == null) {
                    continue;
                }

                // OxygenProperty.value is oxygen deprivation: 0 is healthy, 100 is danger.
                int deprivation = oxygen.getValue();
                if (deprivation > 0) {
                    oxygen.setValue(Math.max(0, deprivation - 8));
                }

                // Refill suit oxygen smoothly when a suit reservoir exists.
                int suitCurrent = oxygen.getOxygenInSuit();
                int suitMax = oxygen.getMaxSpaceSuitCap();
                if (suitMax > 0 && suitCurrent < suitMax) {
                    oxygen.setOxygenInSuit(Math.min(suitMax, suitCurrent + 20));
                }
            }
        }
    }

    private static void setStableFood(World world, boolean enabled, String source) {
        stableFood = enabled;
        nextMaintenanceNs = 0L;
        log(source + ": Stable Food " + (enabled ? "ON (smooth recovery)." : "OFF."));
    }

    private static void setStableRest(World world, boolean enabled, String source) {
        stableRest = enabled;
        nextMaintenanceNs = 0L;
        log(source + ": Stable Rest " + (enabled ? "ON (smooth recovery)." : "OFF."));
    }

    private static void setStableMood(World world, boolean enabled, String source) {
        stableMood = enabled;
        nextMaintenanceNs = 0L;
        log(source + ": Stable Mood " + (enabled ? "ON (smooth support)." : "OFF."));
    }

    private static void setStableComfort(World world, boolean enabled, String source) {
        stableComfort = enabled;
        nextMaintenanceNs = 0L;
        log(source + ": Stable Comfort " + (enabled ? "ON (smooth support)." : "OFF."));
    }

    private static void maintainStableFood(World world) {
        Array<Ship> ships = world.getShips();
        if (ships == null) return;

        for (Ship ship : ships) {
            if (ship == null || !ship.isPlayerShip()) continue;
            Array<Character> chars = ship.getCharacters();
            if (chars == null) continue;

            for (Character character : chars) {
                if (character == null || !character.isPlayerChar()) continue;

                Properties.FoodProperty food = character.getFoodProp();
                if (food == null || food.getValue() >= 85) continue;

                fi.bugbyte.spacehaven.stuff.Production.Edible belly = food.getBelly();
                if (belly == null) continue;

                belly.protein += 0.06f;
                belly.carbs += 0.06f;
                belly.fat += 0.06f;
                belly.vitamins += 0.02f;
            }
        }
    }

    private static void maintainStableRest(World world) {
        Array<Ship> ships = world.getShips();
        if (ships == null) return;

        for (Ship ship : ships) {
            if (ship == null || !ship.isPlayerShip()) continue;
            Array<Character> chars = ship.getCharacters();
            if (chars == null) continue;

            for (Character character : chars) {
                if (character == null || !character.isPlayerChar()) continue;

                Properties.RestProperty rest = character.getRestProp();
                if (rest == null) continue;

                int current = character.getEnergy();
                int max = character.getMaxEnergy();
                if (max > 0 && current < max) {
                    rest.setValue(Math.min(max, current + 3));
                }
            }
        }
    }

    private static void maintainStableMood(World world) {
        Array<Ship> ships = world.getShips();
        if (ships == null) return;

        for (Ship ship : ships) {
            if (ship == null || !ship.isPlayerShip()) continue;
            Array<Character> chars = ship.getCharacters();
            if (chars == null) continue;

            for (Character character : chars) {
                if (character == null || !character.isPlayerChar()) continue;

                Properties.MoodProperty mood = character.getMoodProp();
                if (mood == null) continue;

                int current = mood.getValue();
                int target = Math.min(mood.getMax(), 85);
                if (current < target) {
                    mood.setValue(Math.min(target, current + 2));
                }
            }
        }
    }

    private static void maintainStableComfort(World world) {
        Array<Ship> ships = world.getShips();
        if (ships == null) return;

        for (Ship ship : ships) {
            if (ship == null || !ship.isPlayerShip()) continue;
            Array<Character> chars = ship.getCharacters();
            if (chars == null) continue;

            for (Character character : chars) {
                if (character == null || !character.isPlayerChar()) continue;

                Properties.ComfortProperty comfort = character.getComfortProp();
                if (comfort == null) continue;

                int effective = comfort.getValue();
                if (effective < 80) {
                    int raw = getRawPropertyValue(comfort, effective);
                    comfort.setValue(Math.min(100, raw + 3));
                }

                if (comfort.needsToUseToilet()) {
                    comfort.clearToiletNeed();
                }
            }
        }
    }

    private static int getRawPropertyValue(Properties.Property property, int fallback) {
        try {
            if (!propertyValueFieldLookupDone) {
                propertyValueFieldLookupDone = true;
                propertyValueField = Properties.Property.class.getDeclaredField("value");
                propertyValueField.setAccessible(true);
            }

            if (propertyValueField != null) {
                return propertyValueField.getInt(property);
            }
        } catch (Throwable t) {
            propertyValueField = null;
        }
        return fallback;
    }

    private static void setInstantResearch(World world, boolean enabled, String source) {
        instantResearch = enabled;
        nextMaintenanceNs = 0L;
        nextRichTelemetryNs = 0L;
        log(source + ": Instant Research " + (enabled ? "ON." : "OFF."));
    }

    private static void maintainInstantResearch(World world) {
        Research.ResearchManager manager = world.getResearchManager();
        if (manager == null || manager.getQueueu() == null || manager.getQueueu().size == 0) {
            return;
        }

        Array<Research.ResearchState> queue = manager.getQueueu();
        int[] ids = new int[queue.size];
        int count = 0;
        for (Research.ResearchState state : queue) {
            if (state == null) continue;
            Research.Tech tech = state.getTech();
            if (tech == null || tech.hidden || state.isUnlocked()) continue;
            ids[count++] = state.techId;
        }

        for (int i = 0; i < count; i++) {
            completeResearchTech(world, ids[i], "Instant Research");
        }
    }

    private static boolean completeResearchTech(World world, int techId, String source) {
        Research.ResearchManager manager = world.getResearchManager();
        if (manager == null || manager.getTree() == null) {
            return false;
        }

        Research.TechTreeTechItem item = manager.getTree().getTechById(techId);
        if (item == null) {
            log(source + ": research tech " + techId + " not found in active tree.");
            return false;
        }

        Research.Tech tech = item.getTech();
        if (tech == null || tech.hidden) {
            return false;
        }

        if (!manager.isUnlocked(techId)) {
            manager.debugUnlock(tech);
        }
        manager.removeFromResearchQueue(techId);
        manager.stopAllResearchJobs();
        nextRichTelemetryNs = 0L;
        log(source + ": completed research " + techId + " - " + safeTechName(tech) + ".");
        return true;
    }

    private static int completeAllVisibleResearch(World world, String source) {
        Research.ResearchManager manager = world.getResearchManager();
        if (manager == null || manager.getTree() == null || manager.getTree().getItems() == null) {
            return 0;
        }

        int completed = 0;
        Array<Research.TechTreeTechItem> items = manager.getTree().getItems();
        int[] ids = new int[items.size];
        int count = 0;

        for (Research.TechTreeTechItem item : items) {
            if (item == null) continue;
            Research.Tech tech = item.getTech();
            if (tech == null || tech.hidden) continue;
            if (!manager.isUnlocked(item.techId)) {
                ids[count++] = item.techId;
            }
        }

        for (int i = 0; i < count; i++) {
            Research.TechTreeTechItem item = manager.getTree().getTechById(ids[i]);
            if (item == null) continue;
            Research.Tech tech = item.getTech();
            if (tech == null || tech.hidden) continue;
            manager.debugUnlock(tech);
            manager.removeFromResearchQueue(ids[i]);
            completed++;
        }

        if (completed > 0) {
            manager.stopAllResearchJobs();
        }
        nextRichTelemetryNs = 0L;
        log(source + ": completed " + completed + " visible research technologies.");
        return completed;
    }

    private static Character findPlayerCrewById(World world, int entityId) {
        if (world == null) return null;
        Array<Ship> ships = world.getShips();
        if (ships == null) return null;

        for (Ship ship : ships) {
            if (ship == null || !ship.isPlayerShip()) continue;
            Array<Character> chars = ship.getCharacters();
            if (chars == null) continue;
            for (Character character : chars) {
                if (character != null && character.isPlayerChar() && character.getEntityId() == entityId) {
                    return character;
                }
            }
        }
        return null;
    }

    private static void applyCrewEdits(World world, int entityId, String skillsPayload, String attrsPayload) {
        Character character = findPlayerCrewById(world, entityId);
        if (character == null || character.getPersonality() == null) {
            log("GUI crew apply: player character " + entityId + " not found.");
            return;
        }

        Personality personality = character.getPersonality();
        if (skillsPayload != null && skillsPayload.length() > 0 && !"-".equals(skillsPayload)) {
            String[] rows = skillsPayload.split(";");
            for (String row : rows) {
                String[] values = row.split(",");
                if (values.length < 3) continue;
                try {
                    int saveNr = Integer.parseInt(values[0]);
                    int level = clamp(Integer.parseInt(values[1]), 0, SpaceHavenSettings.maxTotalSkillLevel);
                    int max = clamp(Integer.parseInt(values[2]), level, SpaceHavenSettings.maxTotalSkillLevel);
                    AbsWorkPersonality.Skill skill = findSkillBySaveNr(personality, saveNr);
                    if (skill != null) {
                        skill.setMaxNormalSkillLevel(max);
                        skill.setLevel(level);
                        if (skill.getPotential() > skill.getMaxPotential()) {
                            skill.setPotentialValueNow(skill.getMaxPotential());
                        }
                    }
                } catch (Throwable ignored) {
                }
            }
        }

        if (attrsPayload != null && attrsPayload.length() > 0 && !"-".equals(attrsPayload)) {
            PersonalitySetting.PersonalitySettings settings = personality.getSettings();
            if (settings != null && settings.attributes != null) {
                String[] rows = attrsPayload.split(";");
                for (String row : rows) {
                    String[] values = row.split(",");
                    if (values.length < 2) continue;
                    try {
                        int attrId = Integer.parseInt(values[0]);
                        int points = clamp(Integer.parseInt(values[1]), 1, SpaceHavenSettings.maxAttributePoints);
                        for (PersonalitySetting.Attribute attr : settings.attributes) {
                            if (attr != null && attr.getId() == attrId) {
                                personality.setPoints(attr, points);
                                break;
                            }
                        }
                    } catch (Throwable ignored) {
                    }
                }
                personality.reCalculateCondition();
            }
        }

        nextRichTelemetryNs = 0L;
        log("GUI: applied skills/attributes to " + safeCharacterName(character) + ".");
    }

    private static AbsWorkPersonality.Skill findSkillBySaveNr(Personality personality, int saveNr) {
        if (personality == null || personality.getSkills() == null) return null;
        for (AbsWorkPersonality.Skill skill : personality.getSkills()) {
            if (skill != null && skill.skill != null && skill.skill.saveNR == saveNr) {
                return skill;
            }
        }
        return null;
    }

    private static void maxCrewSkills(World world, int entityId) {
        Character character = findPlayerCrewById(world, entityId);
        if (character == null || character.getPersonality() == null) return;
        Personality personality = character.getPersonality();
        if (personality.getSkills() == null) return;

        for (AbsWorkPersonality.Skill skill : personality.getSkills()) {
            if (skill == null || skill.skill == null || !skill.skill.showOnStats) continue;
            skill.setMaxNormalSkillLevel(SpaceHavenSettings.maxTotalSkillLevel);
            skill.setLevel(SpaceHavenSettings.maxTotalSkillLevel);
            skill.setMaxPotential(0);
            skill.setPotentialValueNow(0);
        }
        nextRichTelemetryNs = 0L;
        log("GUI: maxed visible skills for " + safeCharacterName(character) + ".");
    }

    private static void maxCrewAttributes(World world, int entityId) {
        Character character = findPlayerCrewById(world, entityId);
        if (character == null || character.getPersonality() == null) return;
        Personality personality = character.getPersonality();
        PersonalitySetting.PersonalitySettings settings = personality.getSettings();
        if (settings == null || settings.attributes == null) return;

        for (PersonalitySetting.Attribute attr : settings.attributes) {
            if (attr != null) {
                personality.setPoints(attr, SpaceHavenSettings.maxAttributePoints);
            }
        }
        personality.reCalculateCondition();
        nextRichTelemetryNs = 0L;
        log("GUI: maxed attributes for " + safeCharacterName(character) + ".");
    }

    private static void cureNegativeConditions(World world, int entityId) {
        Character character = findPlayerCrewById(world, entityId);
        if (character == null || character.getPersonality() == null) return;
        Personality personality = character.getPersonality();
        Array<AbstractPersonality.Condition> conditions = personality.getConditions();
        if (conditions == null || conditions.size == 0) return;

        int[] ids = new int[conditions.size];
        int count = 0;
        for (AbstractPersonality.Condition condition : conditions) {
            if (condition == null) continue;
            if (condition.color == AbstractPersonality.ConditionColor.Negative && condition.canBeRemoved()) {
                ids[count++] = condition.getId();
            }
        }

        for (int i = 0; i < count; i++) {
            personality.removeCondition(ids[i]);
        }
        nextRichTelemetryNs = 0L;
        log("GUI: removed " + count + " removable negative conditions from " + safeCharacterName(character) + ".");
    }

    private static String safeCharacterName(Character character) {
        if (character == null) return "-";
        try {
            String name = character.getFullName();
            if (name != null && name.length() > 0) return name;
        } catch (Throwable ignored) {
        }
        return "crew #" + character.getEntityId();
    }

    private static String safeTechName(Research.Tech tech) {
        if (tech == null) return "-";
        try {
            if (tech.name != null && tech.name.id != null) {
                return Game.library.getTextById(tech.name.id).getText();
            }
        } catch (Throwable ignored) {
        }
        return "tech #" + tech.getId();
    }

    private static String b64(String text) {
        if (text == null) text = "";
        return Base64.getEncoder().encodeToString(text.getBytes(java.nio.charset.StandardCharsets.UTF_8));
    }

    private static void updateRichTelemetry(World world) {
        HashMap<Integer, String> crewDetails = new HashMap<Integer, String>();
        StringBuilder crewList = new StringBuilder("CREWLIST|");
        boolean firstCrew = true;

        Array<Ship> ships = world.getShips();
        if (ships != null) {
            for (Ship ship : ships) {
                if (ship == null || !ship.isPlayerShip()) continue;
                Array<Character> chars = ship.getCharacters();
                if (chars == null) continue;
                for (Character character : chars) {
                    if (character == null || !character.isPlayerChar()) continue;
                    int id = character.getEntityId();
                    String name = safeCharacterName(character);
                    if (!firstCrew) crewList.append(';');
                    firstCrew = false;
                    crewList.append(id).append('~').append(b64(name));
                    crewDetails.put(Integer.valueOf(id), buildCrewDetail(character));
                }
            }
        }
        telemetryCrewList = crewList.toString();
        telemetryCrewDetails = crewDetails;

        Research.ResearchManager manager = world.getResearchManager();
        StringBuilder techList = new StringBuilder("TECHLIST|");
        int done = 0;
        int total = 0;
        boolean firstTech = true;
        if (manager != null && manager.getTree() != null && manager.getTree().getItems() != null) {
            for (Research.TechTreeTechItem item : manager.getTree().getItems()) {
                if (item == null) continue;
                Research.Tech tech = item.getTech();
                if (tech == null || tech.hidden) continue;
                int id = item.techId;
                boolean unlocked = manager.isUnlocked(id);
                boolean queued = manager.isQueued(id);
                boolean available = manager.isAvailable(tech);
                String state = unlocked ? "DONE" : (queued ? "QUEUED" : (available ? "AVAILABLE" : "LOCKED"));
                total++;
                if (unlocked) done++;
                if (!firstTech) techList.append(';');
                firstTech = false;
                techList.append(id).append('~').append(state).append('~').append(queued ? '1' : '0')
                    .append('~').append(b64(safeTechName(tech)));
            }
        }
        telemetryTechList = techList.toString();
        telemetryResearchDone = done;
        telemetryResearchTotal = total;
    }

    private static String buildCrewDetail(Character character) {
        StringBuilder out = new StringBuilder("CREWDETAIL");
        out.append("|id=").append(character.getEntityId());
        out.append("|name=").append(b64(safeCharacterName(character)));
        out.append("|maxSkill=").append(SpaceHavenSettings.maxTotalSkillLevel);
        out.append("|maxAttr=").append(SpaceHavenSettings.maxAttributePoints);

        Personality personality = character.getPersonality();
        StringBuilder skills = new StringBuilder();
        StringBuilder attrs = new StringBuilder();
        StringBuilder negNames = new StringBuilder();
        int negCount = 0;

        if (personality != null) {
            if (personality.getSkills() != null) {
                boolean first = true;
                for (AbsWorkPersonality.Skill skill : personality.getSkills()) {
                    if (skill == null || skill.skill == null || !skill.skill.showOnStats) continue;
                    if (!first) skills.append(';');
                    first = false;
                    skills.append(skill.skill.saveNR).append(',')
                        .append(skill.getNormalLevel()).append(',')
                        .append(skill.getMaxNormalSkillLevel()).append(',')
                        .append(b64(skill.skill.getName()));
                }
            }

            PersonalitySetting.PersonalitySettings settings = personality.getSettings();
            if (settings != null && settings.attributes != null) {
                boolean first = true;
                for (PersonalitySetting.Attribute attr : settings.attributes) {
                    if (attr == null) continue;
                    if (!first) attrs.append(';');
                    first = false;
                    attrs.append(attr.getId()).append(',')
                        .append(personality.getPoints(attr)).append(',')
                        .append(b64(attr.getName()));
                }
            }

            Array<AbstractPersonality.Condition> conditions = personality.getConditions();
            if (conditions != null) {
                for (AbstractPersonality.Condition condition : conditions) {
                    if (condition == null) continue;
                    if (condition.color == AbstractPersonality.ConditionColor.Negative) {
                        if (negCount > 0) negNames.append(';');
                        negNames.append(b64(condition.getNamePlain()));
                        negCount++;
                    }
                }
            }
        }

        out.append("|skills=").append(skills);
        out.append("|attrs=").append(attrs);
        out.append("|negativeCount=").append(negCount);
        out.append("|negativeNames=").append(negNames);
        return out.toString();
    }

    private static void captureInfiniteResourceFloors(World world) {
        infiniteTrackedWorld = world;
        infiniteResourceFloors.clear();

        for (int resourceId : INFINITE_RESOURCE_IDS) {
            int total = countResourceAcrossPlayerShips(world, resourceId);
            if (total > 0) {
                infiniteResourceFloors.put(Integer.valueOf(resourceId), Integer.valueOf(total));
            }
        }
    }

    private static void maintainInfiniteResourceFloors(World world) {
        for (int resourceId : INFINITE_RESOURCE_IDS) {
            Integer floorObj = infiniteResourceFloors.get(Integer.valueOf(resourceId));
            int current = countResourceAcrossPlayerShips(world, resourceId);

            if (floorObj == null) {
                if (current > 0) {
                    infiniteResourceFloors.put(Integer.valueOf(resourceId), Integer.valueOf(current));
                }
                continue;
            }

            int floor = floorObj.intValue();
            if (current >= floor) {
                continue;
            }

            int missing = floor - current;
            Ship ship = findPrimaryPlayerShip(world);
            if (ship == null) {
                continue;
            }

            int restored = addResourceExactToShip(ship, resourceId, missing);
            if (restored > 0) {
                log("Infinite Resources restored +" + restored + " of resource ID " + resourceId
                    + " (" + current + " -> " + (current + restored) + ", floor=" + floor + ").");
            }
        }
    }

    private static void updateTelemetry(World world) {
        telemetryWorldLoaded = true;

        TradingHelper.Bank bank = world.getPlayerBank();
        telemetryCredits = bank != null ? bank.getCreditsAvailable() : 0;
        telemetryHyperfuel = countResourceAcrossPlayerShips(world, HYPERFUEL_ID);

        Ship ship = findPrimaryPlayerShip(world);
        telemetryShipName = ship != null ? sanitizeField(safeShipName(ship)) : "-";
        telemetryCrewCount = countPlayerCrew(world);
    }

    private static World getLoadedWorld() {
        Game game = Game.getInstance();
        if (game == null) {
            return null;
        }

        Gamestate state = game.getCurrentState();
        if (!(state instanceof HavenGameState)) {
            return null;
        }

        HavenGameState havenState = (HavenGameState) state;
        return havenState.getCurrentWorld();
    }

    private static void addCredits(World world, int amount, String source) {
        TradingHelper.Bank bank = world.getPlayerBank();
        if (bank == null) {
            log(source + " credits ignored: player bank is null.");
            return;
        }

        int before = bank.getCreditsAvailable();
        bank.addCredits(amount);
        int after = bank.getCreditsAvailable();
        telemetryCredits = after;
        log(source + ": +" + amount + " credits (" + before + " -> " + after + ")");
    }

    private static void addResourceLive(World world, int resourceId, int amount, String source) {
        Ship ship = findPrimaryPlayerShip(world);
        if (ship == null) {
            log(source + " ignored: no player ship found in current world.");
            return;
        }

        int before = countResource(ship, resourceId);
        int added = addResourceExactToShip(ship, resourceId, amount);
        int after = countResource(ship, resourceId);

        if (infiniteResources && added > 0) {
            int totalAcrossShips = countResourceAcrossPlayerShips(world, resourceId);
            Integer oldFloor = infiniteResourceFloors.get(Integer.valueOf(resourceId));
            if (oldFloor == null || totalAcrossShips > oldFloor.intValue()) {
                infiniteResourceFloors.put(Integer.valueOf(resourceId), Integer.valueOf(totalAcrossShips));
            }
        }

        if (resourceId == HYPERFUEL_ID) {
            telemetryHyperfuel = countResourceAcrossPlayerShips(world, HYPERFUEL_ID);
        }

        log(source + ": requested +" + amount + " resource ID " + resourceId
            + "; live delta +" + (after - before) + " (" + before + " -> " + after + ").");
    }

    private static int addResourceExactToShip(Ship ship, int resourceId, int requested) {
        if (ship == null || requested <= 0) {
            return 0;
        }

        Array<Storage.ItemStorage> storages = ship.getStorage();
        if (storages == null || storages.size == 0) {
            return 0;
        }

        int remaining = requested;
        int addedTotal = 0;

        for (Storage.ItemStorage storage : storages) {
            if (remaining <= 0) {
                break;
            }
            if (!isNormalStorage(storage) || !storage.canStore(resourceId)) {
                continue;
            }
            int added = putWithinFreeCapacity(storage, resourceId, remaining);
            remaining -= added;
            addedTotal += added;
        }

        if (remaining > 0) {
            for (Storage.ItemStorage storage : storages) {
                if (remaining <= 0) {
                    break;
                }
                if (!isNormalStorage(storage)) {
                    continue;
                }
                int added = putWithinFreeCapacity(storage, resourceId, remaining);
                remaining -= added;
                addedTotal += added;
            }
        }

        if (remaining > 0) {
            Storage.ItemStorage target = findOverflowTargetForResource(storages, resourceId);
            if (target != null && target.getInventory() != null) {
                int before = target.getInventory().getAmountOf(resourceId);
                target.getInventory().put(resourceId, remaining);
                int after = target.getInventory().getAmountOf(resourceId);
                int added = Math.max(0, after - before);
                if (added > 0) {
                    target.redoStorageGraphicsFully();
                    remaining -= added;
                    addedTotal += added;
                }
            }
        }

        return addedTotal;
    }

    private static Storage.ItemStorage findOverflowTargetForResource(
            Array<Storage.ItemStorage> storages, int resourceId) {
        Storage.ItemStorage firstNormal = null;
        Storage.ItemStorage firstAccepting = null;

        for (Storage.ItemStorage storage : storages) {
            if (!isNormalStorage(storage) || storage.getInventory() == null) {
                continue;
            }
            if (firstNormal == null) {
                firstNormal = storage;
            }
            if (firstAccepting == null && storage.canStore(resourceId)) {
                firstAccepting = storage;
            }
            if (storage.getInventory().getAmountOf(resourceId) > 0) {
                return storage;
            }
        }

        return firstAccepting != null ? firstAccepting : firstNormal;
    }

    private static int putWithinFreeCapacity(Storage.ItemStorage storage, int resourceId, int requested) {
        if (storage == null || storage.getInventory() == null || requested <= 0) {
            return 0;
        }

        Storage.Inventory inv = storage.getInventory();
        int free = storage.capacity - inv.getInStorageSize() - inv.getReservedInSize();
        if (free <= 0) {
            return 0;
        }

        int amount = Math.min(requested, free);
        int before = inv.getAmountOf(resourceId);
        inv.put(resourceId, amount);
        int after = inv.getAmountOf(resourceId);
        int added = Math.max(0, after - before);

        if (added > 0) {
            storage.redoStorageGraphicsFully();
        }
        return added;
    }

    private static Ship findPrimaryPlayerShip(World world) {
        Array<Ship> ships = world.getShips();
        if (ships == null || ships.size == 0) {
            return null;
        }

        Ship firstPlayerShip = null;

        for (Ship ship : ships) {
            if (ship == null || !ship.isPlayerShip()) {
                continue;
            }
            if (firstPlayerShip == null) {
                firstPlayerShip = ship;
            }

            Array<Storage.ItemStorage> storages = ship.getStorage();
            if (storages != null && storages.size > 0
                    && ship.getCharacters() != null && ship.getCharacters().size > 0) {
                return ship;
            }
        }

        return firstPlayerShip;
    }

    private static boolean isNormalStorage(Storage.ItemStorage storage) {
        if (storage == null || storage.notRealStorage) {
            return false;
        }
        if (storage.isBodyStorage()) {
            return false;
        }
        return !storage.dontUseAsNormalStorage();
    }

    private static int countResource(Ship ship, int resourceId) {
        int total = 0;
        Array<Storage.ItemStorage> storages = ship.getStorage();
        if (storages == null) {
            return 0;
        }

        for (Storage.ItemStorage storage : storages) {
            if (storage == null || storage.getInventory() == null) {
                continue;
            }
            total += storage.getInventory().getAmountOf(resourceId);
        }
        return total;
    }

    private static int countResourceAcrossPlayerShips(World world, int resourceId) {
        if (world == null) {
            return 0;
        }

        Array<Ship> ships = world.getShips();
        if (ships == null) {
            return 0;
        }

        int total = 0;
        for (Ship ship : ships) {
            if (ship != null && ship.isPlayerShip()) {
                total += countResource(ship, resourceId);
            }
        }
        return total;
    }

    private static int countPlayerCrew(World world) {
        if (world == null) {
            return 0;
        }

        Array<Ship> ships = world.getShips();
        if (ships == null) {
            return 0;
        }

        int total = 0;
        for (Ship ship : ships) {
            if (ship == null || !ship.isPlayerShip()) {
                continue;
            }

            Array<Character> chars = ship.getCharacters();
            if (chars == null) {
                continue;
            }

            for (Character character : chars) {
                if (character != null && character.isPlayerChar()) {
                    total++;
                }
            }
        }
        return total;
    }

    private static String safeShipName(Ship ship) {
        try {
            String name = ship.getName();
            if (name != null && name.length() > 0) {
                return name;
            }
        } catch (Throwable ignored) {
        }
        return "player ship #" + ship.getShipId();
    }

    private static String keyName(int keycode) {
        if (keycode == Input.Keys.F1) {
            return "F1";
        }
        if (keycode == Input.Keys.F2) {
            return "F2";
        }
        if (keycode == Input.Keys.F3) {
            return "F3";
        }
        if (keycode == Input.Keys.F4) {
            return "F4";
        }
        if (keycode == Input.Keys.F5) return "F5";
        if (keycode == Input.Keys.F6) return "F6";
        if (keycode == Input.Keys.F7) return "F7";
        if (keycode == Input.Keys.F8) return "F8";
        if (keycode == Input.Keys.F9) return "F9";
        if (keycode == Input.Keys.F10) return "F10";
        return "key " + keycode;
    }

    private static int clamp(int value, int min, int max) {
        if (value < min) return min;
        if (value > max) return max;
        return value;
    }

    private static String sanitizeField(String value) {
        if (value == null) return "-";
        return value.replace('|', '/').replace('\r', ' ').replace('\n', ' ');
    }

    private static void startGuiServer() {
        Thread serverThread = new Thread(new Runnable() {
            public void run() {
                ServerSocket server = null;
                try {
                    server = new ServerSocket(GUI_PORT, 16, InetAddress.getByName("127.0.0.1"));
                    server.setSoTimeout(1000);
                    log("External GUI server listening on 127.0.0.1:" + GUI_PORT + ".");

                    while (true) {
                        try {
                            Socket socket = server.accept();
                            handleGuiClient(socket);
                        } catch (SocketTimeoutException ignored) {
                        } catch (Throwable clientError) {
                            System.err.println("[SpaceHavenLiveTrainer] GUI client error: " + clientError);
                        }
                    }
                } catch (Throwable t) {
                    System.err.println("[SpaceHavenLiveTrainer] GUI server failed: " + t);
                    t.printStackTrace();
                } finally {
                    if (server != null) {
                        try { server.close(); } catch (Throwable ignored) {}
                    }
                }
            }
        }, "SpaceHavenLiveTrainer-GUI");
        serverThread.setDaemon(true);
        serverThread.start();
    }

    private static void handleGuiClient(Socket socket) throws Exception {
        socket.setSoTimeout(1500);
        BufferedReader reader = new BufferedReader(new InputStreamReader(socket.getInputStream(), "UTF-8"));
        PrintWriter writer = new PrintWriter(socket.getOutputStream(), true);

        String line = reader.readLine();
        String response = handleGuiRequest(line);
        writer.println(response);
        writer.flush();
        socket.close();
    }

    private static String handleGuiRequest(String line) {
        if (line == null) {
            return "ERR|empty";
        }

        String[] parts = line.trim().split("\\|");
        String op = parts.length > 0 ? parts[0].toUpperCase() : "";

        try {
            if ("PING".equals(op)) {
                return "PONG|version=" + VERSION;
            }

            if ("STATUS".equals(op)) {
                return "STATUS|version=" + VERSION
                    + "|world=" + (telemetryWorldLoaded ? "1" : "0")
                    + "|credits=" + telemetryCredits
                    + "|hyperfuel=" + telemetryHyperfuel
                    + "|crew=" + telemetryCrewCount
                    + "|infiniteResources=" + (infiniteResources ? "1" : "0")
                    + "|infiniteHealth=" + (infiniteHealth ? "1" : "0")
                    + "|infiniteOxygen=" + (infiniteOxygen ? "1" : "0")
                    + "|stableFood=" + (stableFood ? "1" : "0")
                    + "|stableRest=" + (stableRest ? "1" : "0")
                    + "|stableMood=" + (stableMood ? "1" : "0")
                    + "|stableComfort=" + (stableComfort ? "1" : "0")
                    + "|instantResearch=" + (instantResearch ? "1" : "0")
                    + "|researchDone=" + telemetryResearchDone
                    + "|researchTotal=" + telemetryResearchTotal
                    + "|ship=" + sanitizeField(telemetryShipName);
            }

            if ("ADD_CREDITS".equals(op) && parts.length >= 2) {
                int amount = Integer.parseInt(parts[1]);
                COMMAND_QUEUE.add(TrainerCommand.addCredits(amount));
                return "OK|queued=ADD_CREDITS";
            }

            if ("ADD_RESOURCE".equals(op) && parts.length >= 3) {
                int resourceId = Integer.parseInt(parts[1]);
                int amount = Integer.parseInt(parts[2]);
                COMMAND_QUEUE.add(TrainerCommand.addResource(resourceId, amount));
                return "OK|queued=ADD_RESOURCE";
            }

            if ("SET_INFINITE_RESOURCES".equals(op) && parts.length >= 2) {
                boolean enabled = "1".equals(parts[1]) || "true".equalsIgnoreCase(parts[1]);
                COMMAND_QUEUE.add(TrainerCommand.setInfiniteResources(enabled));
                return "OK|queued=SET_INFINITE_RESOURCES";
            }

            if ("SET_INFINITE_HEALTH".equals(op) && parts.length >= 2) {
                boolean enabled = "1".equals(parts[1]) || "true".equalsIgnoreCase(parts[1]);
                COMMAND_QUEUE.add(TrainerCommand.setInfiniteHealth(enabled));
                return "OK|queued=SET_INFINITE_HEALTH";
            }

            if ("SET_INFINITE_OXYGEN".equals(op) && parts.length >= 2) {
                boolean enabled = "1".equals(parts[1]) || "true".equalsIgnoreCase(parts[1]);
                COMMAND_QUEUE.add(TrainerCommand.setInfiniteOxygen(enabled));
                return "OK|queued=SET_INFINITE_OXYGEN";
            }
            if ("SET_STABLE_FOOD".equals(op) && parts.length >= 2) {
                boolean enabled = "1".equals(parts[1]) || "true".equalsIgnoreCase(parts[1]);
                COMMAND_QUEUE.add(TrainerCommand.setStableFood(enabled));
                return "OK|queued=SET_STABLE_FOOD";
            }
            if ("SET_STABLE_REST".equals(op) && parts.length >= 2) {
                boolean enabled = "1".equals(parts[1]) || "true".equalsIgnoreCase(parts[1]);
                COMMAND_QUEUE.add(TrainerCommand.setStableRest(enabled));
                return "OK|queued=SET_STABLE_REST";
            }
            if ("SET_STABLE_MOOD".equals(op) && parts.length >= 2) {
                boolean enabled = "1".equals(parts[1]) || "true".equalsIgnoreCase(parts[1]);
                COMMAND_QUEUE.add(TrainerCommand.setStableMood(enabled));
                return "OK|queued=SET_STABLE_MOOD";
            }
            if ("SET_STABLE_COMFORT".equals(op) && parts.length >= 2) {
                boolean enabled = "1".equals(parts[1]) || "true".equalsIgnoreCase(parts[1]);
                COMMAND_QUEUE.add(TrainerCommand.setStableComfort(enabled));
                return "OK|queued=SET_STABLE_COMFORT";
            }
            if ("LIST_CREW".equals(op)) {
                return telemetryCrewList;
            }
            if ("GET_CREW".equals(op) && parts.length >= 2) {
                int entityId = Integer.parseInt(parts[1]);
                String detail = telemetryCrewDetails.get(Integer.valueOf(entityId));
                return detail != null ? detail : "ERR|crew_not_found";
            }
            if ("LIST_TECHS".equals(op)) {
                return telemetryTechList;
            }
            if ("SET_INSTANT_RESEARCH".equals(op) && parts.length >= 2) {
                boolean enabled = "1".equals(parts[1]) || "true".equalsIgnoreCase(parts[1]);
                COMMAND_QUEUE.add(TrainerCommand.setInstantResearch(enabled));
                return "OK|queued=SET_INSTANT_RESEARCH";
            }
            if ("COMPLETE_TECH".equals(op) && parts.length >= 2) {
                COMMAND_QUEUE.add(TrainerCommand.completeTech(Integer.parseInt(parts[1])));
                return "OK|queued=COMPLETE_TECH";
            }
            if ("COMPLETE_ALL_TECH".equals(op)) {
                COMMAND_QUEUE.add(TrainerCommand.completeAllTech());
                return "OK|queued=COMPLETE_ALL_TECH";
            }
            if ("APPLY_CREW".equals(op) && parts.length >= 4) {
                int entityId = Integer.parseInt(parts[1]);
                COMMAND_QUEUE.add(TrainerCommand.applyCrew(entityId, parts[2], parts[3]));
                return "OK|queued=APPLY_CREW";
            }
            if ("MAX_CREW_SKILLS".equals(op) && parts.length >= 2) {
                COMMAND_QUEUE.add(TrainerCommand.simpleTarget("MAX_CREW_SKILLS", Integer.parseInt(parts[1])));
                return "OK|queued=MAX_CREW_SKILLS";
            }
            if ("MAX_CREW_ATTRS".equals(op) && parts.length >= 2) {
                COMMAND_QUEUE.add(TrainerCommand.simpleTarget("MAX_CREW_ATTRS", Integer.parseInt(parts[1])));
                return "OK|queued=MAX_CREW_ATTRS";
            }
            if ("CURE_CREW_NEGATIVE".equals(op) && parts.length >= 2) {
                COMMAND_QUEUE.add(TrainerCommand.simpleTarget("CURE_CREW_NEGATIVE", Integer.parseInt(parts[1])));
                return "OK|queued=CURE_CREW_NEGATIVE";
            }

            return "ERR|unknown_request";
        } catch (Throwable t) {
            return "ERR|" + sanitizeField(String.valueOf(t.getMessage()));
        }
    }

    private static void log(String message) {
        System.out.println("[SpaceHavenLiveTrainer] " + message);
    }

    private static final class TrainerCommand {
        final String action;
        final int resourceId;
        final int amount;
        final boolean enabled;
        final int targetId;
        final String payloadA;
        final String payloadB;

        private TrainerCommand(String action, int resourceId, int amount, boolean enabled,
                               int targetId, String payloadA, String payloadB) {
            this.action = action;
            this.resourceId = resourceId;
            this.amount = amount;
            this.enabled = enabled;
            this.targetId = targetId;
            this.payloadA = payloadA;
            this.payloadB = payloadB;
        }

        static TrainerCommand addCredits(int amount) {
            return new TrainerCommand("ADD_CREDITS", 0, amount, false, 0, null, null);
        }
        static TrainerCommand addResource(int resourceId, int amount) {
            return new TrainerCommand("ADD_RESOURCE", resourceId, amount, false, 0, null, null);
        }
        static TrainerCommand toggle(String action, boolean enabled) {
            return new TrainerCommand(action, 0, 0, enabled, 0, null, null);
        }
        static TrainerCommand setInfiniteResources(boolean enabled) { return toggle("SET_INFINITE_RESOURCES", enabled); }
        static TrainerCommand setInfiniteHealth(boolean enabled) { return toggle("SET_INFINITE_HEALTH", enabled); }
        static TrainerCommand setInfiniteOxygen(boolean enabled) { return toggle("SET_INFINITE_OXYGEN", enabled); }
        static TrainerCommand setStableFood(boolean enabled) { return toggle("SET_STABLE_FOOD", enabled); }
        static TrainerCommand setStableRest(boolean enabled) { return toggle("SET_STABLE_REST", enabled); }
        static TrainerCommand setStableMood(boolean enabled) { return toggle("SET_STABLE_MOOD", enabled); }
        static TrainerCommand setStableComfort(boolean enabled) { return toggle("SET_STABLE_COMFORT", enabled); }
        static TrainerCommand setInstantResearch(boolean enabled) { return toggle("SET_INSTANT_RESEARCH", enabled); }
        static TrainerCommand completeTech(int techId) {
            return new TrainerCommand("COMPLETE_TECH", 0, 0, false, techId, null, null);
        }
        static TrainerCommand completeAllTech() {
            return new TrainerCommand("COMPLETE_ALL_TECH", 0, 0, false, 0, null, null);
        }
        static TrainerCommand applyCrew(int entityId, String skills, String attrs) {
            return new TrainerCommand("APPLY_CREW", 0, 0, false, entityId, skills, attrs);
        }
        static TrainerCommand simpleTarget(String action, int entityId) {
            return new TrainerCommand(action, 0, 0, false, entityId, null, null);
        }
    }
}
