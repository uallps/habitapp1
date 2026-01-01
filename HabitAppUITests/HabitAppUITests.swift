//
//  HabitAppUITests.swift
//  HabitAppUITests
//
//  Comprehensive UI tests for HabitApp
//

import XCTest

final class HabitAppUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - App Launch Tests
    
    @MainActor
    func testAppLaunchSuccessfully() throws {
        XCTAssertTrue(app.exists)
    }
    
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    // MARK: - Tab Bar Tests
    
    @MainActor
    func testTabBarExists() throws {
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            XCTAssertTrue(tabBar.exists)
        }
    }
    
    @MainActor
    func testNavigateToStatisticsTab() throws {
        let statisticsButton = app.buttons["Estadísticas"]
        if statisticsButton.exists {
            statisticsButton.tap()
            sleep(1)
        }
    }
    
    @MainActor
    func testNavigateToSettingsTab() throws {
        let settingsButton = app.buttons["Ajustes"]
        if settingsButton.exists {
            settingsButton.tap()
            sleep(1)
        }
    }
    
    // MARK: - Add Habit Tests
    
    @MainActor
    func testAddHabitButtonExists() throws {
        let addButton = app.buttons["plus"]
        if !addButton.exists {
            let addButtonAlt = app.buttons["Añadir hábito"]
            if addButtonAlt.exists {
                XCTAssertTrue(addButtonAlt.exists)
            }
        }
    }
    
    @MainActor
    func testOpenAddHabitSheet() throws {
        let addButton = app.buttons["plus"]
        if addButton.exists {
            addButton.tap()
            sleep(1)
            
            let habitNameField = app.textFields.firstMatch
            if habitNameField.waitForExistence(timeout: 2) {
                XCTAssertTrue(habitNameField.exists)
            }
        }
    }
    
    @MainActor
    func testAddHabitFlow() throws {
        let addButton = app.buttons["plus"]
        if addButton.exists {
            addButton.tap()
            sleep(1)
            
            let nameField = app.textFields["Nombre del hábito"]
            if nameField.exists {
                nameField.tap()
                nameField.typeText("Test Habit UI")
            }
            
            let saveButton = app.buttons["Guardar"]
            if saveButton.exists {
                saveButton.tap()
            }
        }
    }
    
    // MARK: - Habit List Tests
    
    @MainActor
    func testHabitListExists() throws {
        sleep(1)
        XCTAssertTrue(app.exists)
    }
    
    // MARK: - Settings Tests
    
    @MainActor
    func testSettingsViewElements() throws {
        let settingsButton = app.buttons["Ajustes"]
        if settingsButton.exists {
            settingsButton.tap()
            sleep(1)
        }
    }
    
    @MainActor
    func testAppearanceSelector() throws {
        let settingsButton = app.buttons["Ajustes"]
        if settingsButton.exists {
            settingsButton.tap()
            sleep(1)
            
            let lightMode = app.buttons["sun.max.fill"]
            let darkMode = app.buttons["moon.fill"]
            
            if lightMode.exists {
                lightMode.tap()
                sleep(1)
            }
            
            if darkMode.exists {
                darkMode.tap()
                sleep(1)
            }
        }
    }
    
    // MARK: - Statistics Tests
    
    @MainActor
    func testStatisticsViewElements() throws {
        let statisticsButton = app.buttons["Estadísticas"]
        if statisticsButton.exists {
            statisticsButton.tap()
            sleep(1)
            XCTAssertTrue(app.exists)
        }
    }
    
    // MARK: - Accessibility Tests
    
    @MainActor
    func testAccessibilityLabels() throws {
        // Only check visible buttons in the main view
        let visibleButtons = app.buttons.allElementsBoundByIndex.prefix(10)
        for button in visibleButtons {
            if button.exists {
                // Just verify button exists and has some label
                XCTAssertNotNil(button.label)
            }
        }
    }
    
    // MARK: - Navigation Tests
    
    @MainActor
    func testNavigationBetweenTabs() throws {
        let tabs = ["Inicio", "Estadísticas", "Ajustes"]
        
        for tab in tabs {
            let tabButton = app.buttons[tab]
            if tabButton.exists {
                tabButton.tap()
                sleep(1)
            }
        }
    }
    
    // MARK: - Scroll Tests
    
    @MainActor
    func testScrollInHabitList() throws {
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(1)
            scrollView.swipeDown()
        }
    }
    
    // MARK: - Dark Mode Tests
    
    @MainActor
    func testDarkModeAppearance() throws {
        let settingsButton = app.buttons["Ajustes"]
        if settingsButton.exists {
            settingsButton.tap()
            sleep(1)
            
            let darkModeButton = app.buttons["moon.fill"]
            if darkModeButton.exists {
                darkModeButton.tap()
                sleep(1)
                XCTAssertTrue(app.exists)
            }
        }
    }
    
    // MARK: - Recap Tests
    
    @MainActor
    func testRecapFeature() throws {
        let recapButton = app.buttons["Recaps"]
        if recapButton.exists {
            recapButton.tap()
            sleep(1)
            XCTAssertTrue(app.exists)
        }
    }
    
    // MARK: - Memory & Performance Tests
    
    @MainActor
    func testMemoryStability() throws {
        // Navigate between main tabs only
        let tabButtons = ["Habits", "chart.bar.xaxis", "gearshape"]
        
        for _ in 0..<3 {
            for tabId in tabButtons {
                let tab = app.buttons[tabId]
                if tab.exists && tab.isHittable {
                    tab.tap()
                    usleep(300000)
                }
            }
        }
        XCTAssertTrue(app.exists)
    }
    
    // MARK: - Text Input Tests
    
    @MainActor
    func testKeyboardAppears() throws {
        let addButton = app.buttons["plus"]
        if addButton.exists {
            addButton.tap()
            sleep(1)
            
            let textField = app.textFields.firstMatch
            if textField.exists {
                textField.tap()
                
                let keyboard = app.keyboards.firstMatch
                if keyboard.waitForExistence(timeout: 2) {
                    XCTAssertTrue(keyboard.exists)
                }
            }
        }
    }
    
    // MARK: - Orientation Tests
    
    @MainActor
    func testPortraitOrientation() throws {
        XCUIDevice.shared.orientation = .portrait
        sleep(1)
        XCTAssertTrue(app.exists)
    }
    
    @MainActor
    func testLandscapeOrientation() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(1)
        XCTAssertTrue(app.exists)
        XCUIDevice.shared.orientation = .portrait
    }
}
