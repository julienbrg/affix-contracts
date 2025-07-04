// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.24;

/**
 * @title AffixRegistry
 * @dev Registry contract for managing documents issued by a specific institution
 */
contract AffixRegistry {
    // Institution details
    address public admin;
    string public institutionName;
    string public institutionUrl;

    // Agent management
    mapping(address => bool) public agents;
    address[] public agentList;

    // Document structure
    struct Document {
        string cid;
        uint256 timestamp;
        bool exists;
        string metadata; // Optional metadata field
        address issuedBy; // Track which agent issued the document
    }

    // Mapping from IPFS CID to Document
    mapping(string => Document) public documents;

    // Array of all document CIDs for enumeration
    string[] public documentCids;

    // Events
    event DocumentIssued(string indexed cid, uint256 timestamp, string metadata, address indexed issuedBy);

    event AgentAdded(address indexed agent, address indexed addedBy);

    event AgentRevoked(address indexed agent, address indexed revokedBy);

    event InstitutionNameUpdated(string oldName, string newName);

    event InstitutionUrlUpdated(string oldUrl, string newUrl);

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier documentNotExists(string memory cid) {
        require(!documents[cid].exists, "Document already exists");
        _;
    }

    modifier validAgent(address agent) {
        require(agent != address(0), "Invalid agent address");
        _;
    }

    /**
     * @dev Constructor to initialize the registry
     * @param _admin The address of the institution admin
     * @param _name The name of the institution
     * @param _url The URL associated with the institution
     */
    constructor(address _admin, string memory _name, string memory _url) {
        require(_admin != address(0), "Invalid admin address");
        require(bytes(_name).length > 0, "Institution name cannot be empty");
        require(bytes(_url).length > 0, "Institution URL cannot be empty");

        admin = _admin;
        institutionName = _name;
        institutionUrl = _url;
    }

    /**
     * @dev Add an agent (only admin can call this)
     * @param agent The address of the agent to add
     */
    function addAgent(address agent) external onlyAdmin validAgent(agent) {
        require(!agents[agent], "Agent already exists");

        agents[agent] = true;
        agentList.push(agent);

        emit AgentAdded(agent, msg.sender);
    }

    /**
     * @dev Revoke an agent (only admin can call this)
     * @param agent The address of the agent to revoke
     */
    function revokeAgent(address agent) external onlyAdmin {
        require(agents[agent], "Agent does not exist");

        agents[agent] = false;

        // Remove from agentList
        for (uint256 i = 0; i < agentList.length; i++) {
            if (agentList[i] == agent) {
                agentList[i] = agentList[agentList.length - 1];
                agentList.pop();
                break;
            }
        }

        emit AgentRevoked(agent, msg.sender);
    }

    /**
     * @dev Issue a new document (callable by anyone who can issue documents)
     * @param cid The IPFS CID of the document
     */
    function issueDocument(string memory cid) external {
        require(canIssueDocuments(msg.sender), "Not authorized to issue documents");
        _issueDocument(cid, "");
    }

    /**
     * @dev Issue a new document (CALLABLE BY ANYONE FOR TESTS ONLY)
     * @param cid The IPFS CID of the document
     * @notice METHOD MUST BE REMOVE FOR PRODUCTION USE
     */
    function issueDocumentOpenBar(string memory cid) external {
        _issueDocument(cid, "");
    }

    /**
     * @dev Issue a new document with metadata (callable by anyone who can issue documents)
     * @param cid The IPFS CID of the document
     * @param metadata Additional metadata for the document
     */
    function issueDocumentWithMetadata(string memory cid, string memory metadata) external {
        require(canIssueDocuments(msg.sender), "Not authorized to issue documents");
        _issueDocument(cid, metadata);
    }

    /**
     * @dev Internal function to issue a document
     * @param cid The IPFS CID of the document
     * @param metadata Additional metadata for the document
     */
    function _issueDocument(string memory cid, string memory metadata) internal documentNotExists(cid) {
        require(bytes(cid).length > 0, "IPFS CID cannot be empty");

        documents[cid] = Document({
            cid: cid,
            timestamp: block.timestamp,
            exists: true,
            metadata: metadata,
            issuedBy: msg.sender
        });

        documentCids.push(cid);

        emit DocumentIssued(cid, block.timestamp, metadata, msg.sender);
    }

    /**
     * @dev Verify if a document exists and get its details
     * @param cid The IPFS CID to verify
     * @return exists Whether the document exists
     * @return timestamp When the document was issued
     * @return institutionName_ The name of the issuing institution
     * @return institutionUrl_ The URL of the issuing institution
     */
    function verifyDocument(
        string memory cid
    )
        external
        view
        returns (bool exists, uint256 timestamp, string memory institutionName_, string memory institutionUrl_)
    {
        Document memory doc = documents[cid];
        return (doc.exists, doc.timestamp, institutionName, institutionUrl);
    }

    /**
     * @dev Get full document details including metadata and issuer
     * @param cid The IPFS CID to query
     * @return exists Whether the document exists
     * @return timestamp When the document was issued
     * @return institutionName_ The name of the issuing institution
     * @return institutionUrl_ The URL of the issuing institution
     * @return metadata Additional metadata
     * @return issuedBy The address that issued the document
     */
    function getDocumentDetails(
        string memory cid
    )
        external
        view
        returns (
            bool exists,
            uint256 timestamp,
            string memory institutionName_,
            string memory institutionUrl_,
            string memory metadata,
            address issuedBy
        )
    {
        Document memory doc = documents[cid];
        return (doc.exists, doc.timestamp, institutionName, institutionUrl, doc.metadata, doc.issuedBy);
    }

    /**
     * @dev Update institution name (only callable by the admin)
     * @param newName The new name for the institution
     */
    function updateInstitutionName(string memory newName) external onlyAdmin {
        require(bytes(newName).length > 0, "Institution name cannot be empty");

        string memory oldName = institutionName;
        institutionName = newName;

        emit InstitutionNameUpdated(oldName, newName);
    }

    /**
     * @dev Update institution URL (only callable by the admin)
     * @param newUrl The new URL for the institution
     */
    function updateInstitutionUrl(string memory newUrl) external onlyAdmin {
        require(bytes(newUrl).length > 0, "Institution URL cannot be empty");

        string memory oldUrl = institutionUrl;
        institutionUrl = newUrl;

        emit InstitutionUrlUpdated(oldUrl, newUrl);
    }

    /**
     * @dev Check if an address is an authorized agent
     * @param agent The address to check
     * @return Boolean indicating if the address is an agent
     */
    function isAgent(address agent) external view returns (bool) {
        return agents[agent];
    }

    /**
     * @dev Check if an address can issue documents (admin or agent)
     * @param issuer The address to check
     * @return Boolean indicating if the address can issue documents
     */
    function canIssueDocuments(address issuer) public view returns (bool) {
        return issuer == admin || agents[issuer];
    }

    /**
     * @dev Get the total number of active agents
     * @return The count of active agents
     */
    function getAgentCount() external view returns (uint256) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < agentList.length; i++) {
            if (agents[agentList[i]]) activeCount++;
        }
        return activeCount;
    }

    /**
     * @dev Get all active agents
     * @return Array of active agent addresses
     */
    function getActiveAgents() external view returns (address[] memory) {
        uint256 activeCount = 0;

        // First pass: count active agents
        for (uint256 i = 0; i < agentList.length; i++) {
            if (agents[agentList[i]]) activeCount++;
        }

        // Second pass: populate array
        address[] memory activeAgents = new address[](activeCount);
        uint256 index = 0;
        for (uint256 i = 0; i < agentList.length; i++) {
            if (agents[agentList[i]]) {
                activeAgents[index] = agentList[i];
                index++;
            }
        }

        return activeAgents;
    }

    /**
     * @dev Get the total number of documents issued
     * @return The count of documents
     */
    function getDocumentCount() external view returns (uint256) {
        return documentCids.length;
    }

    /**
     * @dev Get document CID by index
     * @param index The index in the documentCids array
     * @return The document CID
     */
    function getDocumentCidByIndex(uint256 index) external view returns (string memory) {
        require(index < documentCids.length, "Index out of bounds");
        return documentCids[index];
    }

    /**
     * @dev Get all document CIDs
     * @return Array of all document CIDs
     */
    function getAllDocumentCids() external view returns (string[] memory) {
        return documentCids;
    }

    /**
     * @dev Check if the contract is properly initialized
     * @return Boolean indicating if the contract is valid
     */
    function isValidRegistry() external view returns (bool) {
        return admin != address(0) && bytes(institutionName).length > 0 && bytes(institutionUrl).length > 0;
    }

    /**
     * @dev Get registry information
     * @return admin_ The admin address
     * @return institutionName_ The institution name
     * @return institutionUrl_ The institution URL
     * @return documentCount The total number of documents
     * @return agentCount The total number of active agents
     */
    function getRegistryInfo()
        external
        view
        returns (
            address admin_,
            string memory institutionName_,
            string memory institutionUrl_,
            uint256 documentCount,
            uint256 agentCount
        )
    {
        uint256 activeAgentCount = 0;
        for (uint256 i = 0; i < agentList.length; i++) {
            if (agents[agentList[i]]) activeAgentCount++;
        }

        return (admin, institutionName, institutionUrl, documentCids.length, activeAgentCount);
    }
}
