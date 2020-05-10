import CLibical
import Foundation

typealias LibicalComponent = OpaquePointer
typealias LibicalProperty = OpaquePointer
typealias LibicalParameter = OpaquePointer

protocol LibicalComponentConvertible {
    func libicalComponent() -> LibicalComponent
}

protocol LibicalPropertyConvertible {
    func libicalProperty() -> LibicalProperty
}

protocol LibicalParameterConvertible {
    func libicalParameter() -> LibicalParameter
}


extension DateComponents {
    var icaltime: icaltimetype {
        icaltimetype(year: Int32(year ?? 0),
                     month: Int32(month ?? 0),
                     day: Int32(day ?? 0),
                     hour: Int32(hour ?? 0),
                     minute: Int32(minute ?? 0),
                     second: Int32(second ?? 0),
                     is_date: 0,
                     is_daylight: 0,
                     zone: timeZone?.icalTimeZone)
    }
}

/// In a VEvent the time of the event can be specificed using a start and end time
/// or a start time and a duration.
public enum EventTime {
    case startEnd(DateComponents, DateComponents)
    case startDuration(DateComponents, TimeInterval)
}


public enum Calscale {
    case gregorian
}

public typealias CalendarUserAddress = String
public typealias CommonName = String

public enum CalendarUserType: Equatable {

    /// Experimental type
    case x(String)

    /// An individual
    case individual

    /// A group of individuals
    case group

    /// A physical resource
    case resource

    /// A room resource
    case room

    /// Unknown resource type
    case unknown
}

extension CalendarUserType: LibicalPropertyConvertible {
    func libicalProperty() -> LibicalProperty {
        switch self {
        case .x(let xType):
            let parameter = icalparameter_new_cutype(ICAL_CUTYPE_X)
            icalparameter_set_x(parameter, xType)
            return parameter!
        case .individual:
            return icalparameter_new_cutype(ICAL_CUTYPE_INDIVIDUAL)
        case .group:
            return icalparameter_new_cutype(ICAL_CUTYPE_GROUP)
        case .resource:
            return icalparameter_new_cutype(ICAL_CUTYPE_RESOURCE)
        case .room:
            return icalparameter_new_cutype(ICAL_CUTYPE_ROOM)
        case .unknown:
            return icalparameter_new_cutype(ICAL_CUTYPE_UNKNOWN)
        }

    }
}

public enum EventParticipationStatus: Equatable {
    case needsAction
    case accepted
    case decliend
    case tentative
    case delegated
    case x(String)
}

extension EventParticipationStatus: LibicalParameterConvertible {
    func libicalParameter() -> LibicalParameter {
        switch self {

        case .needsAction:
            return icalparameter_new_partstat(ICAL_PARTSTAT_NEEDSACTION)
        case .accepted:
            return icalparameter_new_partstat(ICAL_PARTSTAT_ACCEPTED)
        case .decliend:
            return icalparameter_new_partstat(ICAL_PARTSTAT_DECLINED)
        case .tentative:
            return icalparameter_new_partstat(ICAL_PARTSTAT_TENTATIVE)
        case .delegated:
            return icalparameter_new_partstat(ICAL_PARTSTAT_DELEGATED)
        case .x(let xType):
            let parameter = icalparameter_new_partstat(ICAL_PARTSTAT_X)
            icalparameter_set_x(parameter, xType)
            return parameter!
        }
    }


}

public enum Role: Equatable {
    case chair
    case requiredParticipant
    case optionalParticipant
    case nonParticipant
    case x(String)
}

extension Role: LibicalParameterConvertible {
    func libicalParameter() -> LibicalParameter {
        switch self {
        case .chair:
            return icalparameter_new_role(ICAL_ROLE_CHAIR)
        case .requiredParticipant:
            return icalparameter_new_role(ICAL_ROLE_REQPARTICIPANT)
        case .optionalParticipant:
            return icalparameter_new_role(ICAL_ROLE_OPTPARTICIPANT)
        case .nonParticipant:
            return icalparameter_new_role(ICAL_ROLE_NONPARTICIPANT)
        case .x(let xType):
            let parameter = icalparameter_new_role(ICAL_ROLE_X)
            icalparameter_set_x(parameter, xType)
            return parameter!
        }
    }


}

public struct Attendee {
    public init(address: CalendarUserAddress,
                type: CalendarUserType = .individual,
                participationStatus: EventParticipationStatus = .needsAction,
                role: Role = .requiredParticipant,
                member: CalendarUserAddress? = nil,
                delegatedTo: [CalendarUserAddress]? = nil,
                delegatedFrom: [CalendarUserAddress]? = nil,
                sentBy: CalendarUserAddress? = nil,
                commonName: CommonName? = nil) {
        self.address = address
        self.type = type
        self.participationStatus = participationStatus
        self.role = role
        self.member = member
        self.delegatedTo = delegatedTo
        self.delegatedFrom = delegatedFrom
        self.sentBy = sentBy
        self.commonName = commonName
    }


    public var address: CalendarUserAddress
    public var type: CalendarUserType = .individual
    public var participationStatus: EventParticipationStatus = .needsAction
    public var role: Role = .requiredParticipant
    public var member: CalendarUserAddress?
    public var delegatedTo: [CalendarUserAddress]?
    public var delegatedFrom: [CalendarUserAddress]?
    public var sentBy: CalendarUserAddress?

    /// Common name for the attendee calendar user,
    /// e.g. John Smith.
    public var commonName: CommonName?
}

extension Attendee: LibicalPropertyConvertible {
    func libicalProperty() -> LibicalProperty {
        let property = icalproperty_new_attendee(self.address)
        if type != .individual {
            icalproperty_add_parameter(property, type.libicalProperty())
        }

        if participationStatus != .needsAction {
            icalproperty_add_parameter(property, participationStatus.libicalParameter())
        }

        if role != .requiredParticipant {
            icalproperty_add_parameter(property, role.libicalParameter())
        }

        if let delegatedTo = delegatedTo {
            let string = delegatedTo.joined(separator: ",")
            icalproperty_add_parameter(property, icalparameter_new_delegatedto(string))
        }

        if let delegatedFrom = delegatedFrom {
            let string = delegatedFrom.joined(separator: ",")
            icalproperty_add_parameter(property, icalparameter_new_delegatedfrom(string))
        }

        if let sentBy = sentBy {
            icalproperty_add_parameter(property, icalparameter_new_sentby(sentBy))
        }

        if let commonName = commonName {
            icalproperty_add_parameter(property, icalparameter_new_cn(commonName))
        }
        return property!
    }
}

public struct Organizer {
    var address: CalendarUserAddress
    var commonName: CommonName?
    var sentBy: CalendarUserAddress?
}


public enum Transparency {
    case opaque
    case transparent
}

extension Transparency: LibicalPropertyConvertible {
    func libicalProperty() -> LibicalProperty {
        switch self {
        case .opaque:
            return icalproperty_new_transp(ICAL_TRANSP_OPAQUE)
        default:
            return icalproperty_new_transp(ICAL_TRANSP_TRANSPARENT)
        }
    }


}

public struct VEvent {
    public init(summary: String, dtstamp: Date = Date(), dtstart: DateComponents, dtend: DateComponents? = nil) {
        self.summary = summary
        self.dtstamp = dtstamp
        self.dtstart = dtstart
        self.dtend = dtend
    }

    /// A short summary or subject for the calendar component.
    ///
    /// See [RFC 5543 Section 3.8.1.12](https://tools.ietf.org/html/rfc5545#section-3.8.1.12) for details.
    public var summary: String

    public var description: String?

    // dtstamp must be in UTC
    public var dtstamp: Date

    /// Start time of the event
    public var dtstart: DateComponents

    /// End time of the event
    public var dtend: DateComponents?

    public var uid: String = UUID().uuidString

    public var created: Date = Date()

    public var recurranceRule: RecurranceRule?

    public var duration: TimeInterval?

    public var attendees: [Attendee]? = nil

    public var transparency: Transparency = .opaque
}

extension VEvent: LibicalComponentConvertible {
    func libicalComponent() -> LibicalComponent {
        let comp = icalcomponent_new_vevent()

        let dtstampProperty = icalproperty_new_dtstamp(dtstamp.icalTime(utc: true))
        icalcomponent_add_property(comp, dtstampProperty)

        let dtstartProperty = icalproperty_new_dtstart(dtstart.date!.icalTime())

        if let timezone = dtstart.timeZone {
            icalproperty_add_parameter(dtstartProperty, icalparameter_new_tzid(timezone.identifier))
        }
        icalcomponent_add_property(comp, dtstartProperty)

        if let dtend = dtend {
            let dtendProperty = icalproperty_new_dtend(dtend.date!.icalTime())
            if let timezone = dtend.timeZone {
                icalproperty_add_parameter(dtendProperty, icalparameter_new_tzid(timezone.identifier))
            }
            icalcomponent_add_property(comp, dtendProperty)
        }

        icalcomponent_add_property(comp, icalproperty_new_summary(summary))
        icalcomponent_add_property(comp, icalproperty_new_uid(uid))
        if let description = description {
            icalcomponent_add_property(comp, icalproperty_new_description(description))
        }

        icalcomponent_add_property(comp, transparency.libicalProperty())
        icalcomponent_add_property(comp, icalproperty_new_created(created.icalTime(utc: true)))

        attendees?.forEach({ (attendee) in
            icalcomponent_add_property(comp, attendee.libicalProperty())
        })
        return comp!
    }
}
