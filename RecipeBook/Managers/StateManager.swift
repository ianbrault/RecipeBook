//
//  StateManager.swift
//  RecipeBook
//
//  Created by Ian Brault on 4/30/23.
//

import Foundation

class State {

    enum Item {
        case recipe
        case folder
    }

    // use a separate data type for encoding/decoding
    struct Data: Codable {
        let userId: String
        let userKey: UUID?
        let root: UUID?
        let recipes: [Recipe]
        let folders: [RecipeFolder]
        let offlineOperationQueue: OperationQueue

        static func empty() -> Data {
            return Data(userId: "", userKey: nil, root: nil, recipes: [], folders: [], offlineOperationQueue: OperationQueue())
        }
    }

    static let manager = State()

    // user ID and key
    var userId: String = ""
    var userKey: UUID? = nil

    // ID of the root folder
    var root: UUID? = nil
    // recipe/folder lists
    var recipes: [Recipe] = []
    var folders: [RecipeFolder] = []
    // maps IDs to recipes/folders
    // managed volatilely, not put in storage
    var recipeMap: [UUID: Recipe] = [:]
    var folderMap: [UUID: RecipeFolder] = [:]

    // has communication with the server been established?
    var serverCommunicationEstablished: Bool = false
    // queue up operations that were done while offline
    var offlineOperationQueue: OperationQueue = OperationQueue()

    private init() {}

    private func loadRecipes(recipes: [Recipe]) {
        self.recipes = recipes
        for recipe in self.recipes {
            self.recipeMap[recipe.uuid] = recipe
        }
    }

    private func loadFolders(folders: [RecipeFolder]) {
        self.folders = folders
        for folder in self.folders {
            self.folderMap[folder.uuid] = folder
        }
    }

    func load() -> RBError? {
        switch PersistenceManager.loadState() {
        case .success(let data):
            self.userId = data.userId
            self.userKey = data.userKey
            self.root = data.root
            self.loadRecipes(recipes: data.recipes)
            self.loadFolders(folders: data.folders)
            self.offlineOperationQueue = data.offlineOperationQueue
            return nil

        case .failure(let error):
            return error
        }
    }

    func store() -> RBError? {
        let data = Data(
            userId: self.userId,
            userKey: self.userKey,
            root: self.root,
            recipes: self.recipes,
            folders: self.folders,
            offlineOperationQueue: self.offlineOperationQueue
        )
        return PersistenceManager.storeState(state: data)
    }

    func processOfflineOperations(handler: @escaping (RBError?) -> ()) {
        self.offlineOperationQueue.processOperations(handler: handler)
    }

    func addUserInfo(info: UserLoginResponse) -> RBError? {
        self.userId = info.id
        self.userKey = info.key
        self.root = info.root
        for recipe in info.recipes {
            self.recipes.append(recipe)
            self.recipeMap[recipe.uuid] = recipe
        }
        for folder in info.folders {
            self.folders.append(folder)
            self.folderMap[folder.uuid] = folder
        }

        return self.store()
    }

    func getRecipe(uuid: UUID) -> Recipe? {
        return self.recipeMap[uuid]
    }

    func getFolder(uuid: UUID) -> RecipeFolder? {
        return self.folderMap[uuid]
    }

    func addRecipe(recipe: Recipe) -> RBError? {
        // add the recipe to the stored recipe list
        self.recipes.append(recipe)
        // and to the volatile recipe map
        self.recipeMap[recipe.uuid] = recipe
        // and then add it to the parent folder
        if let folder = self.getFolder(uuid: recipe.folderId) {
            folder.addRecipe(uuid: recipe.uuid)
        } else {
            return .missingItem(.folder, recipe.folderId)
        }

        if self.serverCommunicationEstablished {
            API.createItem(recipe: recipe, async: true)
        } else {
            self.offlineOperationQueue.addOperation(.create, recipes: [recipe])
        }
        return self.store()
    }

    func addFolder(folder: RecipeFolder) -> RBError? {
        // add the folder to the stored folder list
        self.folders.append(folder)
        // and to the volatile folder map
        self.folderMap[folder.uuid] = folder
        // and then add it to the parent folder
        if let parentId = folder.folderId {
            if let parentFolder = self.getFolder(uuid: parentId) {
                parentFolder.addSubfolder(uuid: folder.uuid)
            } else {
                return .missingItem(.folder, parentId)
            }
        }

        if self.serverCommunicationEstablished {
            API.createItem(folder: folder, async: true)
        } else {
            self.offlineOperationQueue.addOperation(.create, folders: [folder])
        }
        return self.store()
    }

    func updateRecipe(recipe updatedRecipe: Recipe) -> RBError? {
        guard let recipe = self.getRecipe(uuid: updatedRecipe.uuid) else {
            return .missingItem(.recipe, updatedRecipe.uuid)
        }
        recipe.update(with: updatedRecipe)

        if self.serverCommunicationEstablished {
            API.updateItems(recipes: [recipe], async: true)
        } else {
            self.offlineOperationQueue.addOperation(.update, recipes: [recipe])
        }
        return self.store()
    }

    func updateFolder(folder updatedFolder: RecipeFolder) -> RBError? {
        guard let folder = self.getFolder(uuid: updatedFolder.uuid) else {
            return .missingItem(.folder, updatedFolder.uuid)
        }
        folder.update(with: updatedFolder)

        if self.serverCommunicationEstablished {
            API.updateItems(folders: [folder], async: true)
        } else {
            self.offlineOperationQueue.addOperation(.update, folders: [folder])
        }
        return self.store()
    }

    func removeRecipe(recipe: Recipe) {
        // unhook from the parent folder
        if let parentFolder = self.getFolder(uuid: recipe.folderId) {
            parentFolder.removeRecipe(uuid: recipe.uuid)
        }
        // then remove the recipe itself
        self.recipes.removeAll { $0.uuid == recipe.uuid }
        self.recipeMap.removeValue(forKey: recipe.uuid)
    }

    func removeRecipe(uuid: UUID) {
        if let recipe = self.getRecipe(uuid: uuid) {
            self.removeRecipe(recipe: recipe)
        }
    }

    func removeFolder(folder: RecipeFolder) {
        // guard removal of root
        guard let parentFolderId = folder.folderId else { return }

        // first recursively delete sub-items
        for uuid in folder.subfolders {
            self.removeFolder(uuid: uuid)
        }
        for uuid in folder.recipes {
            self.removeRecipe(uuid: uuid)
        }

        // unhook from the parent folder
        if let parentFolder = self.getFolder(uuid: parentFolderId) {
            parentFolder.removeSubfolder(uuid: folder.uuid)
        }
        // then remove the folder itself
        self.folders.removeAll { $0.uuid == folder.uuid }
        self.folderMap.removeValue(forKey: folder.uuid)
    }

    func removeFolder(uuid: UUID) {
        if let folder = self.getFolder(uuid: uuid) {
            self.removeFolder(folder: folder)
        }
    }

    func deleteItem(uuid: UUID) -> RBError? {
        return self.deleteItems(uuids: [uuid])
    }

    func deleteItems(uuids: [UUID]) -> RBError? {
        var recipes: [UUID] = []
        var folders: [UUID] = []
        for uuid in uuids {
            if let recipe = self.recipeMap[uuid] {
                recipes.append(uuid)
                self.removeRecipe(recipe: recipe)
            } else if let folder = self.folderMap[uuid] {
                folders.append(uuid)
                self.removeFolder(folder: folder)
            } else {
                return .missingItem(.recipe, uuid)
            }
        }

        if self.serverCommunicationEstablished {
            API.deleteItems(recipes: recipes, folders: folders, async: true)
        } else {
            self.offlineOperationQueue.addOperation(.delete, recipeUUIDs: recipes, folderUUIDs: folders)
        }
        return self.store()
    }

    func moveRecipeToFolder(recipe: Recipe, folderId: UUID) -> RBError? {
        // first unhook from the parent folder
        if let oldParentFolder = self.getFolder(uuid: recipe.folderId) {
            oldParentFolder.removeRecipe(uuid: recipe.uuid)
        } else {
            return .missingItem(.folder, recipe.folderId)
        }
        // then add it to the new parent folder
        recipe.folderId = folderId
        if let newParentFolder = self.getFolder(uuid: folderId) {
            newParentFolder.addRecipe(uuid: recipe.uuid)
        } else {
            return .missingItem(.folder, folderId)
        }

        return nil
    }

    func moveFolderToFolder(folder: RecipeFolder, folderId: UUID) -> RBError? {
        // first unhook from the parent folder
        if let oldParentFolderId = folder.folderId {
            if let oldParentFolder = self.getFolder(uuid: oldParentFolderId) {
                oldParentFolder.removeSubfolder(uuid: folder.uuid)
            } else {
                return .missingItem(.folder, oldParentFolderId)
            }
        } else {
            // this branch should never be hit
            // folder ID should only be nil for the root, which should never be modified
            return .cannotModifyRoot
        }
        // then add it to the new parent folder
        folder.folderId = folderId
        if let newParentFolder = self.getFolder(uuid: folderId) {
            newParentFolder.addSubfolder(uuid: folder.uuid)
        } else {
            return .missingItem(.folder, folderId)
        }

        return nil
    }

    func moveItemToFolder(uuid: UUID, folderId: UUID) -> RBError? {
        return self.moveItemsToFolder(uuids: [uuid], folderId: folderId)
    }

    func moveItemsToFolder(uuids: [UUID], folderId: UUID) -> RBError? {
        var recipes: [Recipe] = []
        var folders: [RecipeFolder] = []
        var recipeIds: Set<UUID> = []
        var folderIds: Set<UUID> = []

        if let folder = self.getFolder(uuid: folderId) {
            folders.append(folder)
            folderIds.insert(folderId)
        } else {
            return .missingItem(.folder, folderId)
        }

        for uuid in uuids {
            var error: RBError? = nil
            if let recipe = self.recipeMap[uuid] {
                // track the recipe so it can be updated via the API
                if !recipeIds.contains(uuid) {
                    recipes.append(recipe)
                    recipeIds.insert(uuid)
                }
                // also track the parent folder
                if !folderIds.contains(recipe.folderId) {
                    if let parentFolder = self.getFolder(uuid: recipe.folderId) {
                        folders.append(parentFolder)
                        folderIds.insert(recipe.folderId)
                    } else {
                        error = .missingItem(.folder, recipe.folderId)
                    }
                }
                // then move the recipe
                error = self.moveRecipeToFolder(recipe: recipe, folderId: folderId)
            } else if let folder = self.folderMap[uuid] {
                // track the folder so it can be updated via the API
                if !folderIds.contains(uuid) {
                    folders.append(folder)
                    folderIds.insert(uuid)
                }
                // also track the parent folder
                if let parentFolderId = folder.folderId {
                    if !folderIds.contains(parentFolderId) {
                        if let parentFolder = self.getFolder(uuid: parentFolderId) {
                            folders.append(parentFolder)
                            folderIds.insert(parentFolderId)
                        } else {
                            error = .missingItem(.folder, parentFolderId)
                        }
                    }
                } else {
                    error = .cannotModifyRoot
                }
                // then move the folder
                error = self.moveFolderToFolder(folder: folder, folderId: folderId)
            } else {
                error = .missingItem(.recipe, uuid)
            }
            if let error {
                return error
            }
        }

        if self.serverCommunicationEstablished {
            API.updateItems(recipes: recipes, folders: folders, async: true)
        } else {
            self.offlineOperationQueue.addOperation(.update, recipes: recipes, folders: folders)
        }
        return self.store()
    }

    func clear() {
        // NOTE: this should only be used for development debugging
        guard let rootId = self.root else { return }
        guard let root = self.getFolder(uuid: rootId) else { return }
        let _ = self.deleteItems(uuids: root.subfolders + root.recipes)
    }
}
