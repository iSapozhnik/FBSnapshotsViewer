//
//  KaleidoscopeViewerSpec.swift
//  FBSnapshotsViewer
//
//  Created by Anton Domashnev on 06.05.17.
//  Copyright © 2017 Anton Domashnev. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import FBSnapshotsViewer

private class ProcessLauncherMock: ProcessLauncher {
    var launchedProcessPath: String?
    var launchedProcessArguments: [String]?

    override func launchProcess(at launchPath: String, with arguments: [String]?) {
        launchedProcessPath = launchPath
        launchedProcessArguments = arguments
    }
}

private class OSXApplicationFinderMock: OSXApplicationFinder {
    var applicationURL: URL?

    override func findApplication(with bundleIdentifier: String) -> URL? {
        return applicationURL
    }
}

class KaleidoscopeViewerSpec: QuickSpec {
    override func spec() {
        let subject: KaleidoscopeViewer.Type = KaleidoscopeViewer.self
        var processLauncher: ProcessLauncherMock!
        var osxApplicationFinder: OSXApplicationFinderMock!

        beforeEach {
            processLauncher = ProcessLauncherMock()
            osxApplicationFinder = OSXApplicationFinderMock()
        }

        describe("name") {
            it("is Kaleidoscope") {
                expect(subject.name).to(equal("Kaleidoscope"))
            }
        }

        describe("bundleID") {
            it("is correct") {
                expect(subject.bundleID).to(equal("com.blackpixel.kaleidoscope"))
            }
        }

        describe(".canView") {
            var testResult: SnapshotTestResult!
            var build: Build!
            var testInformation: SnapshotTestInformation!
            
            beforeEach {
                build = Build(date: Date(), applicationName: "MyApp", fbReferenceImageDirectoryURLs: [URL(fileURLWithPath: "foo/bar", isDirectory: true)])
                testInformation = SnapshotTestInformation(testClassName: "ExampleTestClass", testName: "testName", testFilePath: "testFilePath", testLineNumber: 1)
            }

            context("for recorded snapshot test result") {
                beforeEach {
                    testResult = SnapshotTestResult.recorded(testInformation: testInformation, referenceImagePath: "foo/bar/referenceImage.png", build: build)
                }

                it("returns false") {
                    expect(subject.canView(snapshotTestResult: testResult)).to(beFalse())
                }
            }

            context("for failed snapshot test result") {
                beforeEach {
                    testResult = SnapshotTestResult.failed(testInformation: testInformation, referenceImagePath: "foo/bar/referenceImage.png", diffImagePath: "foo/bar/diffImage.png", failedImagePath: "foo/bar/failedImage.png", build: build)
                }

                it("returns true") {
                    expect(subject.canView(snapshotTestResult: testResult)).to(beTrue())
                }
            }
        }

        describe(".isAvailable") {
            context("when application finder finds the app with bundleID") {
                beforeEach {
                    osxApplicationFinder.applicationURL = URL(fileURLWithPath: "foo/bar.app")
                }

                it("is true") {
                    expect(subject.isAvailable(osxApplicationFinder: osxApplicationFinder)).to(beTrue())
                }
            }

            context("when application finder doesn't find the app with bundleID") {
                beforeEach {
                    osxApplicationFinder.applicationURL = nil
                }

                it("is false") {
                    expect(subject.isAvailable(osxApplicationFinder: osxApplicationFinder)).to(beFalse())
                }
            }
        }

        describe(".view") {
            var testResult: SnapshotTestResult!
            var build: Build!
            var testInformation: SnapshotTestInformation!

            beforeEach {
                build = Build(date: Date(), applicationName: "MyApp", fbReferenceImageDirectoryURLs: [URL(fileURLWithPath: "foo/bar", isDirectory: true)])
                testInformation = SnapshotTestInformation(testClassName: "ExampleTestClass", testName: "testName", testFilePath: "testFilePath", testLineNumber: 1)
            }
            
            context("for recorded snapshot test result") {
                beforeEach {
                    testResult = SnapshotTestResult.recorded(testInformation: testInformation, referenceImagePath: "foo/bar/referenceImage.png", build: build)
                }

                it("throws an assertion") {
                    expect { subject.view(snapshotTestResult: testResult, using: processLauncher) }.to(throwAssertion())
                }
            }

            context("for failed snapshot test result") {
                beforeEach {
                    testResult = SnapshotTestResult.failed(testInformation: testInformation, referenceImagePath: "foo/bar/referenceImage.png", diffImagePath: "foo/bar/diffImage.png", failedImagePath: "foo/bar/failedImage.png", build: build)
                }

                it("launches correct process") {
                    subject.view(snapshotTestResult: testResult, using: processLauncher)
                    expect(processLauncher.launchedProcessArguments).to(equal(["foo/bar/referenceImage.png", "foo/bar/failedImage.png"]))
                    expect(processLauncher.launchedProcessPath).to(equal("/usr/local/bin/ksdiff"))
                }
            }
        }
    }
}
