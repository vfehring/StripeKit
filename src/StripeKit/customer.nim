type Customer = object
    id: string
    description: string
    email: string
    name: string
    phone: string
    balance: int
    currency: string
    delinquent: bool
    invoice_prefix: string
    livemode: bool
    next_invoice_sequence: int
    tax_exempt: string
    test_clock: string

proc createCustomer(self: Customer, email: string) =
    echo self.email